from rest_framework import serializers, status
from rest_framework.exceptions import ValidationError
from utils.choice import UserType
from utils.serializers import ImageSerializer
from .models import (Product, ProductImage,ProductStatus,
                     ProductVariant,Option,
                     OptionValue,VariantOptionValue,
                     Category, OptionValueImage)
from checkout.models import OrderDetail
from itertools import product as cartesian_product
from django.db import transaction
import json
from locations.models import Province,Ward
from rest_framework.response import Response



    
class CategoryListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'type', 'descriptions']
    

    
class ProductSerializer(serializers.ModelSerializer):
   
    images = ImageSerializer(many=True, read_only = True)
    upload_images = serializers.ListField(
        child=serializers.ImageField(), write_only=True, required=True
        )

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["owner"] = {
            "id": instance.owner.id,
            "name": f"{instance.owner.first_name} {instance.owner.last_name}".strip(),
        }

        data["category"]={
            "name": instance.category.type
        }

        if instance.province:
            data["province"] = instance.province.full_name


        if instance.ward:
            data["ward"] = instance.ward.full_name

        return data  
    class Meta:
        model = Product
        fields = [
            "id",
            "name",
            "status",
            "owner",
            "description",
            "category",
            "min_price",
            "max_price",
            "images",
            "upload_images",
            "province",
            "ward",
            "active"
            
        ]
        extra_kwargs = {
            'owner': {'read_only': True}, 
            'status': {'read_only': True},
            'active':{'read_only':True}

        }
    
    def validate(self, data):
        name = (data.get('name') or getattr(self.instance, 'name', '')).strip()
        description = (data.get('description') or getattr(self.instance, 'description', '')).strip()
        category = data.get('category') or getattr(self.instance, 'category', None)
        max_price = data.get('max_price') if 'max_price' in data else getattr(self.instance, 'max_price', None)
        min_price = data.get('min_price') if 'min_price' in data else getattr(self.instance, 'min_price', None)
        province = data.get('province') or getattr(self.instance, 'province', None)
        ward = data.get('ward') or getattr(self.instance, 'ward', None)
        ward_located = Ward.objects.filter(code=getattr(ward, 'code', None)).first() if ward else None

        if not name or len(name) < 3:
            raise serializers.ValidationError({"name": "Tên sản phẩm không được để trống và phải ≥3 ký tự."})
        if not description:
            raise serializers.ValidationError({"description": "Mô tả sản phẩm không được để trống."})
        if max_price is not None and min_price is not None and max_price < min_price:
            raise serializers.ValidationError({"mean-price": "Khoảng giá trị không hợp lệ."})
        if not category or not Category.objects.filter(id=category.id).exists():
            raise serializers.ValidationError({"category": "Loại sản phẩm không tồn tại."})
        if ward and (not ward_located or ward_located.province != province):
            raise serializers.ValidationError({"location": "Vị trí không nhất quán."})

        return data

    def validate_upload_images(self, value):
        if not value:
            return value
        if len(value) < 3:
            raise serializers.ValidationError("Cần tối thiểu 3 bức ảnh về sản phẩm!")
        if len(value) > 10:
            raise serializers.ValidationError("Vượt quá số lượng ảnh! (Tối đa là 10)")
        max_size = 10 * 1024 * 1024
        allowed_types = ["image/jpeg", "image/png", "image/jpg"]
        for image in value:
            if image.size > max_size:
                raise serializers.ValidationError(
                    f"Kích thước ảnh {image.name} vượt quá 10MB"
                )
            if image.content_type not in allowed_types:
                raise serializers.ValidationError(
                    f"File {image.name} không đúng định dạng ảnh"
                )
        return value

        
    def create(self, validated_data):
        upload_images = validated_data.pop("upload_images", [])
        owner =  self.context["request"].user
        validated_data["active"] = False

        validated_data["owner"] = owner
        
        product_instance = Product.objects.create(**validated_data)

        for image_file in upload_images:
            ProductImage.objects.create(
                image=image_file,
                alt=f"Image for {product_instance.name}",
                product=product_instance,
            )

        return product_instance
    
    def update(self, instance, validated_data):
        upload_images = validated_data.pop("upload_images", None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if upload_images:
            
            for image_file in upload_images:
                ProductImage.objects.create(
                    image=image_file,
                    alt=f"Image for {instance.name}",
                    product=instance,
                )
        return instance
    
class OptionGetSerializer(serializers.ModelSerializer):
    option_value = serializers.SerializerMethodField()
    class Meta:
        model = Option
        fields = ['id','type',"option_value"]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        return data
    
    def get_option_value(self,obj):
        value = OptionValue.objects.filter(option=obj)
        return OptionValueGetSerializer(value, many=True).data
    
class OptionValueGetSerializer(serializers.ModelSerializer):
    class Meta:
        model = OptionValue
        fields = ['id','value', 'option']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["option"] ={
            "type": instance.option.type
        }
        return data
      
class ProductVariantGetSerializer(serializers.ModelSerializer):
    option_values = serializers.SerializerMethodField()
    product = serializers.SerializerMethodField()

    class Meta:
        model = ProductVariant
        fields = ['id', 'price', 'stock', 'product', 'option_values']

    def get_option_values(self, obj):
        values = OptionValue.objects.filter(
            variant_option_values__product_variant=obj
        )
        return OptionValueGetSerializer(values, many=True).data

    def get_product(self, obj):
        product = obj.product
        # lấy ảnh đầu tiên (nếu có)
        first_image = product.images.first()
        return {
            "id": product.id,
            "name": product.name,
            "image": first_image.image.url if first_image else None
        }


class OptionSerializer(serializers.ModelSerializer):
    values = serializers.ListField(
        child=serializers.CharField(), write_only=True, required=False
    )

    class Meta:
        model = Option
        fields = ["id", "type", "image_require", "product", "values"]
        extra_kwargs = {"product": {"read_only": True}}

    def validate(self, data):
        type_value = data.get('type', getattr(self.instance, 'type', None))
        product_value = data.get('product', getattr(self.instance, 'product', None))

        if Option.objects.filter(
            type=type_value,
            product=product_value
        ).exclude(pk=getattr(self.instance, "pk", None)).exists():
            raise serializers.ValidationError(
                {"type": "Tùy chọn này đã tồn tại cho sản phẩm."}
            )
        return data

    def create(self, validated_data):
        product = self.context.get("product")
        if product:
            validated_data["product"] = product

        values_data = validated_data.pop("values", [])
        option = super().create(validated_data)
        
        for val in values_data:
            value_payload = {"value": val, "option": option.id}  # thêm option id vào payload
            value_serializer = OptionValueSerializer(
                data=value_payload
            )
            value_serializer.is_valid(raise_exception=True)
            value_serializer.save()
        
        return option

class OptionValueSerializer(serializers.ModelSerializer):
    image = ImageSerializer(many=True, read_only=True)
    upload_image = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model = OptionValue
        fields = ["id","value", "option", "image", "upload_image"]

    def validate_upload_image(self, value):
        option = self.context.get("option")
        if option and option.image_require and not value:
            raise serializers.ValidationError(
                f"Option '{option.type}' yêu cầu hình ảnh."
            )

        if not value:
            return value  

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
        print(validated_data)
        upload_image = validated_data.pop("upload_image", None)
        option_value = super().create(validated_data)

        if upload_image:
            OptionValueImage.objects.create(option_value=option_value, image=upload_image)

        return option_value

class VariantOptionValueSerializer(serializers.ModelSerializer):
    product_variant = serializers.PrimaryKeyRelatedField(
        queryset=ProductVariant.objects.all()
    )
    option_value = serializers.PrimaryKeyRelatedField(
        queryset=OptionValue.objects.all()
    )

    class Meta:
        model = VariantOptionValue
        fields = ['product_variant', 'option_value']

    def validate(self, data):
        if not ProductVariant.objects.filter(pk=data['product_variant'].pk).exists():
            raise serializers.ValidationError("Không tìm thấy lựa chọn phù hợp")
        if not OptionValue.objects.filter(pk=data['option_value'].pk).exists():
            raise serializers.ValidationError("Không tìm thấy lựa chọn phù hợp")
        return data

    def create(self, validated_data):
        return VariantOptionValue.objects.create(**validated_data)

class ProductVariantSerializer(serializers.ModelSerializer):
    option_values = serializers.ListField(
        child=serializers.IntegerField(), write_only=True
    )

    class Meta:
        model = ProductVariant
        fields = ["id", "sku", "price", "stock", "option_values"]

    def validate_option_values(self, value):
        product = self.context.get("product")
        if not product:
            raise ValidationError("Product is required in context.")
        print(value)
        # Lấy tất cả Option của product
        required_options = product.options.all()
        required_option_ids = set(required_options.values_list("id", flat=True))

        # Lấy các OptionValue từ value
        option_values_qs = OptionValue.objects.filter(id__in=value)
        option_ids_from_value = list(option_values_qs.values_list("option_id", flat=True))

        # 1. Kiểm tra không có 2 giá trị cùng 1 Option
        if len(option_ids_from_value) != len(set(option_ids_from_value)):
            raise ValidationError(
                "Một Variant không được có 2 giá trị của cùng một Option "
                "(ví dụ: không được có 2 màu sắc hoặc 2 kích thước)."
            )

        # 2. Kiểm tra đủ Option
        if set(option_ids_from_value) != required_option_ids:
            raise ValidationError(
                f"Variant phải chứa đúng một giá trị cho mỗi Option. "
                f"Yêu cầu: {list(required_option_ids)}, nhận: {list(set(option_ids_from_value))}"
            )

        # 3. Kiểm tra tất cả giá trị thuộc về sản phẩm
        valid_option_value_ids = OptionValue.objects.filter(
            option__in=required_options
        ).values_list("id", flat=True)

        for ov_id in value:
            if ov_id not in valid_option_value_ids:
                raise ValidationError(
                    f"Option value id={ov_id} không thuộc product '{product.name}'."
                )

        return value



    def create(self, validated_data):
        option_values_ids = validated_data.pop("option_values", [])
        product = self.context.get("product")

        product_variant = ProductVariant.objects.create(product=product, **validated_data)

        for ov_id in option_values_ids:
            serializer = VariantOptionValueSerializer(data={
                "product_variant": product_variant.id,
                "option_value": ov_id
            })
            serializer.is_valid(raise_exception=True)
            serializer.save()
        return product_variant

class ProductVariantUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductVariant
        fields = ["price", "stock"]

    def validate_price(self, value):
        if value <= 0:
            raise serializers.ValidationError("Price must be greater than zero.")
        return value

class ProductOptionSetupSerializer(serializers.Serializer):
    options = OptionSerializer(many=True)

    def create(self, validated_data):
        product = self.context.get("product")
        if not product:
            raise serializers.ValidationError("Thiếu product trong context.")

        options_data = validated_data.get("options", [])

        with transaction.atomic():

            for option_data in options_data:
                option_serializer = OptionSerializer(
                    data=option_data,  
                    context={"product": product}
                )
                option_serializer.is_valid(raise_exception=True)
                option = option_serializer.save()
                print(options_data)
               
        return {
            "product": product,
            "options": OptionSerializer(product.product_options.all(), many=True).data,
        }

class ProductListSerializer(serializers.ModelSerializer):
    images = ImageSerializer(many=True, read_only=True)
    sold_quantity = serializers.IntegerField(read_only=True)
    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["owner"] = {
            "id": instance.owner.id,
            "name": f"{instance.owner.first_name} {instance.owner.last_name}".strip(),
        }
        if instance.province:
            data["province"] = instance.province.full_name
        if instance.ward:
            data["ward"] = instance.ward.full_name
        return data
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'status', 'description',
            'category', 'max_price', 'min_price', 'images',
            'province', 'ward','sold_quantity'
        ]

class ProductDetailSerializer(serializers.ModelSerializer):
    images = ImageSerializer(many=True, read_only=True)
    variants = ProductVariantGetSerializer(source='product_variant', many=True, read_only=True)
    options = OptionGetSerializer(source='product_options', many=True,read_only=True)
    province = serializers.SlugRelatedField(read_only=True, slug_field='name')
    ward = serializers.SlugRelatedField(read_only=True, slug_field='name')

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'status', 'owner', 'description',
            'category', 'max_price', 'min_price', 'images',
            'province', 'ward', 'variants','sold_quantity','options',
        ]

class OrderRequestSerializer(serializers.ModelSerializer):
    # order_id = serializers.IntegerField(source="order.id", read_only=True)
    # order_date = serializers.DateTimeField(source="order.created_at", read_only=True)
    # product_name = serializers.CharField(source="product.product.name", read_only=True)
    # variant_name = serializers.CharField(source="product.name", read_only=True)
    product_variant = ProductVariantSerializer(source='product', read_only=True)
    class Meta:
        model = OrderDetail   
        fields = ["id", "product_variant", "quantity",
                  "price", "delivery_charge", "delivery_status", "delivery_method", "delivery_route"]

