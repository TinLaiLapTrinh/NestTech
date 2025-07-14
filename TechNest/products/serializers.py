from rest_framework import serializers, status
from utils.choice import UserType
from utils.serializers import ImageSerializer
from .models import (Product,ProductCartItem,
                     ProductImage,ProductStatus,
                     ProductVariant,Option,
                     OptionValue,VariantOptionValue,
                     Category)
from django.db import transaction
import json
from locations.models import District,Province,Ward
from rest_framework.response import Response

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'


class ProductSerializer(serializers.ModelSerializer):
   
    # images = ImageSerializer(many=True, read_only = True)
    # upload_images = serializers.ListField(
    #     child=serializers.ImageField(), write_only=True, required=True
    #     )

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

        if instance.district:
            data["district"] = instance.district.full_name

        if instance.ward:
            data["ward"] = instance.ward.full_name

        return data

        
    
    class Meta:
        model = Product
        fields = [
            "id",
            "name",
            "owner",
            "description",
            "category",
            # "images",
            # "upload_images",
            "province",
            "district",
            "ward"
        ]
        extra_kwargs = {
            'owner': {'read_only': True},  # thường sẽ set theo request.user
            'status': {'read_only': True},  # mặc định là DEPENDING
        }
    def validate(self, data):
        name = data.get('name', '').strip()
        description = data.get('description', '').strip()
        category = data.get('category')

        if not name:
            raise serializers.ValidationError({"name": "Tên sản phẩm không được để trống."})
        if len(name) < 3:
            raise serializers.ValidationError({"name": "Tên sản phẩm quá ngắn (ít nhất 3 ký tự)."})

        if not description:
            raise serializers.ValidationError({"description": "Mô tả sản phẩm không được để trống."})
        
        if not category or not Category.objects.filter(id=category.id).exists():
            raise serializers.ValidationError({"category": "Loại sản phẩm không tồn tại."})
        
        return data
    # def validate_upload_images(self, value):
    #     if not value:
    #         return value
    #     if len(value) < 3:
    #         raise serializers.ValidationError("Cần tối thiểu 3 bức ảnh về dãy trọ!")
    #     if len(value) > 10:
    #         raise serializers.ValidationError("Vượt quá số lượng ảnh! (Tối đa là 10)")
    #     max_size = 10 * 1024 * 1024
    #     allowed_types = ["image/jpeg", "image/png", "image/jpg"]
    #     for image in value:
    #         if image.size > max_size:
    #             raise serializers.ValidationError(
    #                 f"Kích thước ảnh {image.name} vượt quá 10MB"
    #             )
    #         if image.content_type not in allowed_types:
    #             raise serializers.ValidationError(
    #                 f"File {image.name} không đúng định dạng ảnh"
    #             )
    #         return value

        
    def create(self, validated_data):
        # upload_images = validated_data.pop("upload_images", [])

        request = self.context["request"]
        validated_data["owner"] = request.user
        
        product_instance = Product.objects.create(**validated_data)

        # for image_file in upload_images:
        #     ProductImage.objects.create(
        #         image=image_file,
        #         alt=f"Image for {product_instance.name}",
        #         product=product_instance,
        #     )

        return product_instance
    
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
    
class OptionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Option
        fields = ['id','type']

    def validate(self, data):
        product = self.context.get('product')
        type = data.get('type')

        if product.options.filter(type=type).exists():
            raise serializers.ValidationError({"option":" option đã tồn tại."})
       
        return data
    
    def create(self, validated_data):
        product = self.context.get('product')
        if not Product.objects.filter(pk=product.id).exists():
            raise serializers.ValidationError({"product": "Không tìm thấy sản phẩm."})
        validated_data['product']=product

        return super().create(validated_data)
 
class OptionValueGetSerializer(serializers.ModelSerializer):
    class Meta:
        model = OptionValue
        fields = ['value']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        return data
    
class OptionValueCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = OptionValue
        fields = ['value']  # Không cần 'option' từ client
    def validate(self, data):
        option = self.context.get('option')
        value = data.get('value')
        if option.option_values.filter(value=value).exists():
            raise serializers.ValidationError({'option value': 'Lựa chọn đã tồn tại. '})
        return data
    
    def create(self, validated_data):
        option = self.context.get('option')
        if not option:
            raise serializers.ValidationError({"option value": "Không tìm thấy lựa chọn."})
        validated_data['option'] = option
        return super().create(validated_data)

class VariantOptionValueSerializer(serializers.ModelSerializer):
    class Meta:
        model = VariantOptionValue
        fields = ['variant', 'option_value']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        return data
    
    def validate(self, data):
        variant = data.get('variant')
        option_value = data.get('option_value')
        if not ProductVariant.objects.filter(pk = variant).exists():
            raise serializers.ValidationError("Không tìm thấy lựa chọn phù hợp")
        if not OptionValue.objects.filter(pk = option_value).exists():
            raise serializers.ValidationError("Không tìm thấy lựa chọn phù hợp")
        return data
    
    
    
class ProductVariantGetSerializer(serializers.ModelSerializer):
    option_values = serializers.SerializerMethodField()

    class Meta:
        model = ProductVariant
        fields = ['price', 'stock','product','option_values']

    def get_option_values(self, obj):
        values = OptionValue.objects.filter(variantoptionvalue__product_variant=obj)
        return OptionValueGetSerializer(values, many=True).data
    
class ProductVariantCreateSerializer(serializers.ModelSerializer):

    class Meta:
        model = ProductVariant
        fields = ['price', 'stock']

    def validate(self, data):

        return data

    def to_representation(self, instance):
        data = super().to_representation(instance)
        return data
    
    def create(self, validated_data):
        product = self.context.get('product')
        if not product or not Product.objects.filter(pk = product.id).exists():
            raise serializers.ValidationError("Không tìm thấy sản phẩm")

        validated_data['product']=product

        return super().create(validated_data)
    

class VariantOptionValueCreateSerializer(serializers.ModelSerializer):
    product_variant = serializers.PrimaryKeyRelatedField(queryset=ProductVariant.objects.all())
    option_value = serializers.PrimaryKeyRelatedField(queryset=OptionValue.objects.all())
    class Meta:
        model = VariantOptionValue
        fields = ['product_variant', 'option_value']

    def validate(self, data):
        product_variant = data.get('product_variant')
        option_value = data.get('option_value')

        if not product_variant:
            raise serializers.ValidationError({"product_variant": "Không được để trống."})
        
        if not option_value:
            raise serializers.ValidationError({"option_value": "Không được để trống."})

        return data
    
    
    

class ProductWithComponentsSerializer(serializers.Serializer):
    product = serializers.JSONField()
    options = serializers.JSONField()
    option_values = serializers.JSONField()
    variants = serializers.JSONField()

    def to_representation(self, instance):
        return {
            "product": ProductSerializer(instance, context=self.context).data,
            "option": OptionGetSerializer(instance.option.all(), many=True).data,
            "variants": ProductVariantGetSerializer(instance.product_variant.all(), many=True).data,
        }

    def to_internal_value(self, data):
        result = {}

        for key in ['product', 'options', 'option_values', 'variants']:
            raw = data.get(key)
            if isinstance(raw, list):
                raw = raw[0]
            try:
                result[key] = json.loads(raw)
            except Exception:
                raise serializers.ValidationError({key: "Invalid JSON format"})

        # Xử lý upload_images rõ ràng
        # upload_images = data.getlist('upload_images') if hasattr(data, 'getlist') else data.get('upload_images')
        # if not upload_images:
        #     raise serializers.ValidationError({"upload_images": ["This field is required."]})
        
        # result['product']['upload_images'] = upload_images

        return result

    def validate(self, data):
        # kiểm tra tên option có khớp với option value không
        option_types = {opt['type'] for opt in data['options']}
        for ov in data['option_values']:
            if ov['option'] not in option_types:
                raise serializers.ValidationError({"option_values": f"Option '{ov['option']}' không hợp lệ."})

        for v in data['variants']:
            if len(v['option_values']) != len(option_types):
                raise serializers.ValidationError({"variants": "Mỗi biến thể phải có đủ option values."})

        return data

    def create(self, validated_data):

        product_data = validated_data['product']
        options_data = validated_data['options']
        option_values_data = validated_data['option_values']
        variants_data = validated_data['variants']

        request = self.context["request"]
        product_data["owner"] = request.user

        with transaction.atomic():
            product_serializer = ProductSerializer(data=product_data, context=self.context)
            product_serializer.is_valid(raise_exception=True)
            product = product_serializer.save()

            print(product)
            

            # 2. Tạo Options
            option_mapping = {}
            for opt in options_data:
                opt_serializer = OptionCreateSerializer(
                    data={"type": opt['type']},
                    context={"product": product}  
                )
                if not opt_serializer.is_valid():
                    print(opt_serializer.errors)
                    raise serializers.ValidationError({"option ": opt_serializer.errors})
                opt = opt_serializer.save()
                print(opt)
                option_mapping[opt.type] = opt

            print(option_mapping)

            # 3. Tạo OptionValues
            option_value_mapping = {}
            for ov in option_values_data:
                opt_type = ov["option"]
                val = ov["value"]
                ov_serializer = OptionValueCreateSerializer(
                data={
                    "value": ov["value"]
                },
                context={"option": option_mapping[ov["option"]]}
            )
                if not ov_serializer.is_valid():
                    raise serializers.ValidationError({"option_values": opt_serializer.errors})
                ov_instance = ov_serializer.save()
                option_value_mapping[(opt_type, val)] = ov_instance 


            # 4. Tạo Variants
            for var in variants_data:
                option_values = var.pop("option_values", [])
                print(var)
                print(product.id)
                var_serializer = ProductVariantCreateSerializer(
                    data={**var},  # nếu serializer dùng pk
                    context={"product": product}
                )
                if not var_serializer.is_valid():
                    raise serializers.ValidationError({"variant": var_serializer.errors})
                variant = var_serializer.save()
                
                # Nối các Variant với các optionvalue
                for ov in option_values:
                    opt_type = ov["option"]
                    val = ov["value"]
                    ov_instance = option_value_mapping[(opt_type, val)]
                    print(ov_instance.id)
                    print(variant.id)
                    vov_serializer = VariantOptionValueCreateSerializer(
                        data={
                            'product_variant': variant.id,
                            'option_value': ov_instance.id
                        }
                    )

                    if not vov_serializer.is_valid():
                        raise serializers.ValidationError({"variant_option_values": vov_serializer.errors})

                    vov_serializer.save()

                    

        return product
