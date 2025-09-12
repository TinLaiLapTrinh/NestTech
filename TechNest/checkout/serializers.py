from rest_framework import serializers, status
from rest_framework.exceptions import ValidationError
from utils.choice import UserType, DeliveryMethods, DeliveryStatus
from utils.serializers import ImageSerializer
from .models import Order,OrderDetail,ShoppingCart, ShoppingCartItem, OrderDetailConfirmImage
from products.models import ProductVariant, Product, VariantOptionValue, Rate
from locations.models import ShippingRoute, ShippingRate
from products.serializers import ProductVariantGetSerializer
from django.db import transaction
import json
from accounts.models import User
from locations.models import Province,Ward
from rest_framework.response import Response
from decimal import Decimal
from django.db import transaction
from firebase.firebase_config import send_order_notification

class ShoppingCartSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShoppingCart
        fields = []

    def validate(self, data):
        user = self.context['request'].user 
        if ShoppingCart.objects.filter(owner=user).exists():
            raise serializers.ValidationError({"cart": "Người dùng đã sở hữu giỏ hàng"})
        return data

    def create(self, validated_data):
        user = self.context['request'].user
        cart = ShoppingCart.objects.create(owner=user)
        return cart


class ShoppingCartItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShoppingCartItem
        fields = ['product','quantity']
        

    def validate(self, data):
        variant = data.get('product') or getattr(self.instance, 'product', None)
        quantity = data.get('quantity') or getattr(self.instance, 'quantity', None)

        if not variant or quantity is None:
            raise serializers.ValidationError({"detail": "Thiếu sản phẩm hoặc số lượng"})

        if quantity <= 0:
            raise serializers.ValidationError({"quantity": "Số lượng phải lớn hơn 0"})

        if quantity > variant.stock:
            raise serializers.ValidationError({"quantity": "Sản phẩm trong kho không đủ"})

        if 'shopping_cart' not in data:
            cart = self.context.get('cart')
            if not cart:
                raise serializers.ValidationError({"detail": "Giỏ hàng không tồn tại."})
            data['shopping_cart'] = cart

        return data

    def create(self, validated_data):
        product_variant = validated_data['product']
        quantity = validated_data['quantity']
        cart = validated_data['shopping_cart']

        item, created = ShoppingCartItem.objects.get_or_create(
            shopping_cart=cart,
            product=product_variant,
            defaults={'quantity': quantity}
        )

        if not created:
            new_quantity = item.quantity + quantity
            if new_quantity > product_variant.stock:
                raise serializers.ValidationError({"quantity": "Sản phẩm trong kho không đủ"})
            item.quantity = new_quantity
            item.save()

        return item


class ShoppingCartListItemSerializer(serializers.ModelSerializer):
    product = ProductVariantGetSerializer(read_only=True)

    class Meta:
        model = ShoppingCartItem
        fields = ['id','product', 'quantity']




class OrderDetailSerializer(serializers.ModelSerializer):
    price = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    delivery_route = serializers.PrimaryKeyRelatedField(read_only=True)  
    delivery_charge = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)  
    product = serializers.PrimaryKeyRelatedField(queryset=ProductVariant.objects.all())
    image_confirm = ImageSerializer(many=True, read_only = True)

    class Meta:
        model = OrderDetail
        fields = [
            "id","product", "quantity", "price","distance",
            "delivery_route","order",
            "delivery_charge","delivery_status","delivery_person","image_confirm"
        ]
        read_only_fields = ["product", "price","delivery_person","order","image_confirm"]
    
    def to_representation(self, instance):
        
        data = super().to_representation(instance)
        data["product"] = ProductVariantGetSerializer(instance.product).data

        order = instance.order
        data["recieve_info"]= {
                "customer":order.owner.first_name + " " + order.owner.last_name,
                "phone": order.receiver_phone_number,
            }
       
        customer_address = {
            "province": order.province.name,
            "district": order.district.name,
            "ward": order.ward.name,
            "address": order.address,
            "latitude": order.latitude,
            "longitude": order.longitude,
        }


        product_origin = instance.product.product
        supplier_address = {
            "province": product_origin.province.name if product_origin.province else None,
            "district": product_origin.district.name if product_origin.district else None,
            "ward": product_origin.ward.name if product_origin.ward else None,
            "address": getattr(product_origin, "address", None),
            "latitude": getattr(product_origin, "latitude", None),
            "longitude": getattr(product_origin, "longitude", None),
        }


        data["route_info"] = {
            "from": supplier_address,
            "to": customer_address,
        }

        return data

    def validate(self, data):
        product_variant = data.get("product") or getattr(self.instance, 'product', None)
        quantity = data.get("quantity") or getattr(self.instance, 'quantity', None)
        
        if not product_variant:
            raise serializers.ValidationError({"product": "Thiếu sản phẩm"})
        if not quantity or quantity <= 0:
            raise serializers.ValidationError({"quantity": "Số lượng phải lớn hơn 0"})
        if product_variant.stock <= 0:
            raise serializers.ValidationError({"product": "Sản phẩm đã hết hàng"})
        if quantity > product_variant.stock:
            raise serializers.ValidationError({
                "quantity": f"Trong kho chỉ còn {product_variant.stock} sản phẩm"
            })

        return data
    
    def create(self, validated_data):
        """Trừ stock ngay khi tạo OrderDetail"""
        product_variant = validated_data["product"]
        quantity = validated_data["quantity"]


        product_variant.stock -= quantity
        product_variant.save(update_fields=["stock"])


        validated_data["price"] = product_variant.price  

        return super().create(validated_data)
    
    ALLOWED_TRANSITIONS = {
        DeliveryStatus.PENDING: [DeliveryStatus.CONFIRM, DeliveryStatus.CANCELLED],
        DeliveryStatus.CONFIRM: [DeliveryStatus.PROCESSING, DeliveryStatus.CANCELLED],
        DeliveryStatus.PROCESSING: [DeliveryStatus.SHIPPED, DeliveryStatus.CANCELLED],
        DeliveryStatus.SHIPPED: [DeliveryStatus.DELIVERED, DeliveryStatus.RETURNED_TO_SENDER],
        DeliveryStatus.DELIVERED: [],
        DeliveryStatus.RETURNED_TO_SENDER: [],
        DeliveryStatus.CANCELLED: [],
        DeliveryStatus.REFUNDED: [],
    }
    
    def update(self, instance, validated_data):
        old_status = instance.delivery_status
        new_status = validated_data.get("delivery_status", old_status)


        allowed_next = self.ALLOWED_TRANSITIONS.get(old_status, [])
        

        if new_status != old_status and new_status not in allowed_next or new_status == old_status:
            raise serializers.ValidationError({
                "delivery_status": f"Không thể chuyển trạng thái từ '{old_status}' → '{new_status}'"
            })
        
        if old_status == DeliveryStatus.PROCESSING and new_status == DeliveryStatus.SHIPPED:
            delivery_person = User.objects.filter(
                province=instance.order.province,
                user_type=UserType.DELIVER_PERSON
            ).first()
            if delivery_person:
                instance.delivery_person = delivery_person


        if old_status != DeliveryStatus.DELIVERED and new_status == DeliveryStatus.DELIVERED:
            product = instance.product.product
            product.sold_quantity = (product.sold_quantity or 0) + instance.quantity
            product.save(update_fields=["sold_quantity"])



        updated_instance = super().update(instance, validated_data)

        if old_status != new_status: 
            order_owner = instance.order.owner
            variant = instance.product  

            title = "Cập nhật đơn hàng"
            body = (
                f"Đơn hàng {variant.product.name} - {variant.sku} của "
                f"{order_owner.first_name} {order_owner.last_name} "
                f"đã chuyển sang trạng thái: {new_status}"
            )


            send_order_notification(order_owner, title, body)

            print(f"[DEBUG] Sending notification to user {order_owner.id} with status {new_status}")

        return updated_instance
        
class OrderDetailConfirmImageSerializer(serializers.ModelSerializer):
    image = serializers.ImageField()

    class Meta:
        model = OrderDetailConfirmImage
        fields = ["id", "image", "order"]
        extra_kwargs = {"order": {"required": False}}

    def validate(self, attrs):
        order = attrs.get("order") or self.context.get("order")
        if OrderDetailConfirmImage.objects.filter(order=order).exists():
            raise serializers.ValidationError(
                "Đơn hàng này đã có ảnh xác nhận, không thể cập nhật thêm."
            )
        return super().validate(attrs)

    def validate_image(self, value):
        max_size = 10 * 1024 * 1024
        allowed_types = ["image/jpeg", "image/png", "image/jpg"]

        if value.size > max_size:
            raise serializers.ValidationError(
                f"Kích thước ảnh {value.name} vượt quá 10MB"
            )
        if value.content_type not in allowed_types:
            raise serializers.ValidationError(
                f"File {value.name} không đúng định dạng ảnh"
            )
        return value

    def create(self, validated_data):
        return super().create(validated_data)

    
class RateSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(source="owner.username", read_only=True)
    order_id = serializers.IntegerField(source="order_detail.order.id", read_only=True)

    class Meta:
        model = Rate
        fields = [
            "id",
            "rate",
            "content",
            "owner_name",
            "order_id",
            "created_at",
        ]

    def create(self, validated_data):
        
        return super().create(validated_data)




class OrderListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ["id","total","created_at"]


class OrderSerializer(serializers.ModelSerializer):
    order_details = OrderDetailSerializer(many=True)
    total = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    

    class Meta:
        model = Order
        fields = [
            "total", "owner", "province","ward","district",
            "address", "receiver_phone_number", "latitude",
            "longitude","order_details"
        ]
        
        extra_kwargs = {"owner": {"read_only": True}}
    


    def validate(self, data):
        phone_number = data.get("receiver_phone_number")
        if not phone_number:
            raise serializers.ValidationError({"phone": "Thiếu số điện thoại người nhận"})
        if not phone_number.isdigit() or len(phone_number) < 9 or len(phone_number) > 13:
            raise serializers.ValidationError({"phone": "Số điện thoại không hợp lệ"})
        return data

    def create(self, validated_data):
        
        
        details_data = validated_data.pop("order_details")
        
        with transaction.atomic():
            order = Order.objects.create(**validated_data)
            total_price = Decimal("0.00")
            for detail_data in details_data:
                product_variant = detail_data["product"]
                quantity = detail_data["quantity"]
                method = detail_data.get("delivery_method", DeliveryMethods.NORMAL) 

                origin_region = product_variant.product.province.administrative_region
                destination_region = order.province.administrative_region
                try:
                    route = ShippingRoute.objects.get(
                        origin_region=origin_region,
                        destination_region=destination_region
                    )
                except ShippingRoute.DoesNotExist:
                    raise serializers.ValidationError({
                        "delivery": f"Không tìm thấy tuyến vận chuyển từ {origin_region.id} đến {destination_region.id}"
                    })
                

                rate = route.rates.filter(method=method).first()
                if not rate:
                    raise serializers.ValidationError({
                        "delivery": f"Không có phương thức vận chuyển {method} cho tuyến này"
                    })

                delivery_charge = Decimal(rate.price)
                price = Decimal(product_variant.price)


                product_variant.stock -= quantity
                product_variant.save()


                OrderDetail.objects.create(
                    order=order,
                    product=product_variant,
                    quantity=quantity,
                    price=price,
                    delivery_route=route,
                    distance=detail_data["distance"],
                    delivery_charge=delivery_charge,
                    delivery_method=method  
                )

                total_price += (price * quantity + delivery_charge)


            order.total = total_price
            order.save()

        return order
    
class OrderRequestSerializer(serializers.ModelSerializer):
    product_variant = ProductVariantGetSerializer(source='product', read_only=True)

    class Meta:
        model = OrderDetail   
        fields = [
            "id", "quantity", "price", "delivery_charge",
            "delivery_status", "delivery_method",
            "product_variant", "delivery_route",
        ]


