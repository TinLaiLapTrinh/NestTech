from rest_framework import serializers, status
from rest_framework.exceptions import ValidationError
from utils.choice import UserType, DeliveryMethods
from utils.serializers import ImageSerializer
from .models import Order,OrderDetail,ShoppingCart, ShoppingCartItem
from products.models import ProductVariant, Product, VariantOptionValue
from locations.models import ShippingRoute
from products.serializers import ProductVariantGetSerializer
from django.db import transaction
import json
from locations.models import Province,Ward
from rest_framework.response import Response
from decimal import Decimal
from django.db import transaction

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

    class Meta:
        model = OrderDetail
        fields = [
            "product", "quantity", "price",
            "delivery_route", "distance", "delivery_charge"
        ]

    def validate(self, data):
        product_variant = data.get("product")
        quantity = data.get("quantity")

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


class OrderSerializer(serializers.ModelSerializer):
    order_details = OrderDetailSerializer(many=True)
    total = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    

    class Meta:
        model = Order
        fields = [
            "total", "owner", "province",
            "address", "receiver_phone_number", "latitude",
            "longitude","order_details"
        ]


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

                origin_region = product_variant.product.province.region
                destination_region = order.province.region
                try:
                    route = ShippingRoute.objects.get(
                        origin_region=origin_region,
                        destination_region=destination_region
                    )
                except ShippingRoute.DoesNotExist:
                    raise serializers.ValidationError({
                        "delivery": f"Không tìm thấy tuyến vận chuyển từ {origin_region} đến {destination_region}"
                    })

                rate = route.rates.filter(method=method).first()
                if not rate:
                    raise serializers.ValidationError({
                        "delivery": f"Không có phương thức vận chuyển {method} cho tuyến này"
                    })

                delivery_charge = Decimal(rate.price)
                price = Decimal(product_variant.price)

                # Trừ tồn kho
                product_variant.stock -= quantity
                product_variant.save()

                # Tạo OrderDetail
                OrderDetail.objects.create(
                    order=order,
                    product=product_variant,
                    quantity=quantity,
                    price=price,
                    delivery_route=route,
                    distance=detail_data["distance"],
                    delivery_charge=delivery_charge,
                    delivery_method=method  # lưu phương thức vận chuyển
                )

                total_price += (price * quantity + delivery_charge)


            order.total = total_price
            order.save()

        return order