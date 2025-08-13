from rest_framework import serializers, status
from rest_framework.exceptions import ValidationError
from utils.choice import UserType
from utils.serializers import ImageSerializer
from .models import (Product,ProductCartItem,
                     ProductImage,ProductStatus,
                     ProductVariant,Option,
                     OptionValue,VariantOptionValue,
                     Category)
from django.db import transaction
import json
from locations.models import Province,Ward
from rest_framework.response import Response


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
        fields = ['value','id']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        return data
    
class CategoryListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'type', 'descriptions']
    
class CategoryDetailSerializer(serializers.ModelSerializer):
    options = OptionGetSerializer(many=True, read_only=True)

    class Meta:
        model = Category
        fields = ['id', 'type', 'descriptions', 'options']
    
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
            
        ]
        extra_kwargs = {
            'owner': {'read_only': True}, 
            'status': {'read_only': True}, 
        }
    
    def validate(self, data):
        name = data.get('name', '').strip()
        description = data.get('description', '').strip()
        category = data.get('category')
        max_price = data.get('max_price')
        min_price = data.get('min_price')
        ward = data.get('ward')
        province = data.get('province')  
        ward_located = Ward.objects.filter(code=ward.code).first() 


        if not name:
            raise serializers.ValidationError({"name": "Tên sản phẩm không được để trống."})
        if len(name) < 3:
            raise serializers.ValidationError({"name": "Tên sản phẩm quá ngắn (ít nhất 3 ký tự)."})

        if max_price<min_price:
            raise serializers.ValidationError({"mean-price":"Khoảng giá trị không hợp lệ."})

        if not description:
            raise serializers.ValidationError({"description": "Mô tả sản phẩm không được để trống."})
        
        if not category or not Category.objects.filter(id=category.id).exists():
            raise serializers.ValidationError({"category": "Loại sản phẩm không tồn tại."})
        
        if not ward_located or ward_located.province != province:
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

        request = self.context["request"]
        owner =  self.context["request"].user

        validated_data["owner"] = owner
        
        product_instance = Product.objects.create(**validated_data)

        for image_file in upload_images:
            ProductImage.objects.create(
                image=image_file,
                alt=f"Image for {product_instance.name}",
                product=product_instance,
            )

        return product_instance

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

    
class ProductVariantGetSerializer(serializers.ModelSerializer):
    option_values = serializers.SerializerMethodField()

    class Meta:
        model = ProductVariant
        fields = ['price', 'stock','product','option_values']

    def get_option_values(self, obj):
        values = OptionValue.objects.filter(variantoptionvalue__product_variant=obj)
        return OptionValueGetSerializer(values, many=True).data
    
class ProductVariantCreateSerializer(serializers.ModelSerializer):
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

        category_id = product.category_id
        # Lấy danh sách option_value hợp lệ thuộc category
        valid_option_value_ids = OptionValue.objects.filter(
            option__category_id=category_id
        ).values_list("id", flat=True)

        # Kiểm tra từng id
        for ov_id in value:
            if ov_id not in valid_option_value_ids:
                raise ValidationError(
                    f"Option value id={ov_id} không thuộc category '{product.category.type}'."
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
    
class ProductWithComponentsSerializer(serializers.Serializer):
    def to_representation(self, instance):
        return {
            "product": ProductSerializer(instance, context=self.context).data,
            "variants": ProductVariantGetSerializer(instance.product_variant.all(), many=True).data,
        }

    def to_internal_value(self, data):
        result = {}

        optional_keys = ['product', 'options', 'option_values', 'variants']

        for key in optional_keys:
            raw = data.get(key)
            if not raw: 
                continue

            if isinstance(raw, list) and raw:
                raw = raw[0]  

            try:
                result[key] = json.loads(raw)
            except Exception:
                raise serializers.ValidationError({key: "Invalid JSON format"})

        upload_images = (
            data.getlist('upload_images')
            if hasattr(data, 'getlist')
            else data.get('upload_images')
        )
        if not upload_images:
            raise serializers.ValidationError({"upload_images": ["This field is required."]})

        if 'product' in result:
            result['product']['upload_images'] = upload_images

        return result

    def create(self, validated_data):
        product_data = validated_data.get('product', {})
        variants_data = validated_data.get('variants', [])
        request = self.context["request"]

        if product_data:
            product_data["owner"] = request.user

        with transaction.atomic():
            product = None
            if product_data:
                product_serializer = ProductSerializer(data=product_data, context=self.context)
                product_serializer.is_valid(raise_exception=True)
                product = product_serializer.save()

            for variant_item in variants_data:
                variant_serializer = ProductVariantCreateSerializer(
                    data=variant_item,
                    context={'product': product}
                )
                variant_serializer.is_valid(raise_exception=True)
                variant_serializer.save()

        return product
