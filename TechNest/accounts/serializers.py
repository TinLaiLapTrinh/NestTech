from rest_framework import serializers
from .models import User, Follow, AuditLog
from checkout.models import ShoppingCart
from products.models import Category, Product, ProductImage
from utils.serializers import ImageSerializer
from locations.models import Province,District, Ward
from utils.choice import UserType
from django.db import transaction


class UserSerializer(serializers.ModelSerializer):
    follow_count = serializers.SerializerMethodField()
    is_verified = serializers.SerializerMethodField()

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["avatar"] = instance.avatar.url if instance.avatar else ""
        return data

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "password",
            "first_name",
            "last_name",
            "dob",
            "email",
            "address",
            "avatar",
            "phone_number",
            "user_type",
            "follow_count",
            "is_verified",  # 👈 thêm vào output
        ]
        extra_kwargs = {"password": {"write_only": True}}

    def get_follow_count(self, obj):
        return obj.followers.count() if obj.user_type == UserType.SUPPLIER else obj.following.count()

    def get_is_verified(self, obj):
        if obj.user_type == UserType.SUPPLIER:
            latest_log = AuditLog.objects.filter(user=obj).order_by("-timestamp").first()
            return latest_log.verified if latest_log else False
        return None  # khách hàng không cần hiện



class CustomerRegister(serializers.ModelSerializer):
    avatar = serializers.ImageField(required=False)

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["avatar"] = instance.avatar.url if instance.avatar else ""
        return data

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "password",
            "first_name",
            "last_name",
            "avatar",
            "dob",
            "email",
            "address",
            "phone_number",     
        ]
        extra_kwargs = {"password": {"write_only": True}}

    def create(self, validated_data):
        
        user_serializer = UserSerializer(data=validated_data)
        if user_serializer.is_valid():
            user = user_serializer.save(
                is_active=True,
                user_type=UserType.CUSTOMER
            )
            
            ShoppingCart.objects.create(owner=user)
            return user
        else:
            raise serializers.ValidationError(user_serializer.errors)



class SupplierRegister(serializers.ModelSerializer):
    avatar = serializers.ImageField(required=False)

    product_name = serializers.CharField()
    product_address = serializers.CharField()
    product_province = serializers.PrimaryKeyRelatedField(queryset=Province.objects.all())
    product_district = serializers.PrimaryKeyRelatedField(queryset=District.objects.all())
    product_ward = serializers.PrimaryKeyRelatedField(queryset=Ward.objects.all())
    product_description = serializers.CharField()
    product_category = serializers.PrimaryKeyRelatedField(queryset=Category.objects.all())
    product_upload_images = serializers.ListField(
        child=serializers.ImageField(),
        required=False,
        write_only=True
    )
    product_min_price = serializers.DecimalField(max_digits=12, decimal_places=2)
    product_max_price = serializers.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        model = User
        fields = [
            "id", "username", "password", "first_name", "last_name", "avatar",
            "dob", "email", "address", "phone_number",

            "product_name", "product_min_price", "product_max_price",
            "product_description", "product_category", "product_province", "product_district",
            "product_ward", "product_address", "product_upload_images"
        ]
        extra_kwargs = {"password": {"write_only": True}}

    def to_representation(self, instance):
        """
        Định nghĩa cách serialize trả về kết quả. Vì kết quả khi đăng ký
        ta sẽ trả về thông tin của người dùng mới tạo và cả thông tin về
        dãy trọ mà người dùng đã đăng ký (Tức khác với `ModelSerializer`)
        """
        product = instance["product"]
        return {
            "message": "Đăng ký thành công. Tài khoản của bạn sẽ được kích hoạt sau khi sản phẩm được xét duyệt.",
            "user": UserSerializer(instance["user"]).data,
            "product": {
                "name": product.name,
                "address": product.address,
                "images": ImageSerializer(product.images.all(), many=True).data,
            },
        }


    def validate(self, attrs):
        min_price = attrs.get("product_min_price")
        max_price = attrs.get("product_max_price")
        if max_price < min_price:
            raise serializers.ValidationError({"product_min_price": "Khoảng giá trị không hợp lệ."})
        return attrs

    def validate_product_upload_images(self, value):
        """Kiểm tra ảnh sản phẩm."""
        if not value:
            raise serializers.ValidationError("Cần cung cấp ảnh sản phẩm.")
        if len(value) < 3:
            raise serializers.ValidationError("Cần tối thiểu 3 bức ảnh về sản phẩm!")
        if len(value) > 10:
            raise serializers.ValidationError("Vượt quá số lượng ảnh! (Tối đa là 10)")

        max_size = 10 * 1024 * 1024 
        allowed_types = ["image/jpeg", "image/png", "image/jpg"]

        for image in value:
            if image.size > max_size:
                raise serializers.ValidationError(f"Kích thước ảnh {image.name} vượt quá 10MB")
            if getattr(image, "content_type", None) not in allowed_types:
                raise serializers.ValidationError(f"File {image.name} không đúng định dạng ảnh")
        return value

    def create(self, validated_data):
        product_data = {
            "name": validated_data.pop("product_name"),
            "address": validated_data.pop("product_address"),
            "province": validated_data.pop("product_province"),
            "district": validated_data.pop("product_district"),
            "ward": validated_data.pop("product_ward"),
            "description": validated_data.pop("product_description"),
            "category": validated_data.pop("product_category"),
            "min_price": validated_data.pop("product_min_price"),
            "max_price": validated_data.pop("product_max_price"),
        }
        product_images = validated_data.pop("product_upload_images", [])

        password = validated_data.pop("password")

        try:
            with transaction.atomic():
                
                supplier = User.objects.create(**validated_data)
                supplier.set_password(password)
                supplier.user_type = UserType.SUPPLIER
                supplier.active = False
                supplier.save()


                product = Product.objects.create(owner=supplier, **product_data)

                product.active = False
                product.save()


                if product_images:
                    ProductImage.objects.bulk_create([
                        ProductImage(product=product, image=image, alt=f"Image for {product.name}")
                        for image in product_images
                    ])

                return {"user": supplier, "product": product}

        except Exception as e:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({"error": f"Tạo supplier/product thất bại: {str(e)}"})

class FollowSerializer(serializers.ModelSerializer):
    """
    serializer cho theo dõi giữa khách hàng và nhà cung cấp,
    và họ sẽ được thông báo khi nhà cung cấp có thông tin mới qua email, và ngược lại nhà cung cấp
    chỉ coi được người đang follow chính mình
    """

    class Meta:
        model = Follow
        fields = ["active", "followee", "follower"]
        extra_kwargs = {
            "follower": {"read_only": True},
            "followee": {"read_only": True},
            }
        

    def to_representation(self, instance):
        data = super().to_representation(instance)

        data["follower"] = {
            "id": instance.follower.id,
            "name": f"{instance.follower.first_name} {instance.follower.last_name}".strip(),
            "avatar": instance.follower.avatar.url
            if instance.follower.avatar
            else None,
            "email": instance.follower.email,
            "address": instance.follower.address,
            "province": {
                "name": instance.follower.province.name,
            } if instance.follower.province else None,
            "phone_number": instance.follower.phone_number,
            "user_type": instance.follower.user_type,
        }


        data["followee"] = {
            "id": instance.followee.id,
            "name": f"{instance.followee.first_name} {instance.followee.last_name}".strip(),
            "avatar": instance.followee.avatar.url
            if instance.followee.avatar
            else None,
            "email": instance.followee.email,
            "address": instance.followee.address,
            "province": {
                "name": instance.followee.province.name,
            } if instance.followee.province else None,
            "phone_number": instance.followee.phone_number,
             "user_type": instance.followee.user_type,
        }

        return data

    def validate(self, attrs):
        request = self.context["request"]
        follower = request.user
        followee = self.context["followee"]
        
        print(follower.user_type, followee.user_type)

        if follower == followee:
            raise serializers.ValidationError("Bạn không thể tự theo dõi chính mình.")

        if follower.user_type != UserType.CUSTOMER:
            raise serializers.ValidationError("Người dùng theo dõi không hợp lệ.")

        if follower.user_type == followee.user_type:
            raise serializers.ValidationError("Người dùng theo dõi không phù hợp.")

        if Follow.objects.filter(follower=follower, followee=followee).exists():
            raise serializers.ValidationError("Đã theo dõi người này rồi.")

        attrs["follower"] = follower
        attrs["followee"] = followee
        return attrs


    def create(self, validated_data):
        return Follow.objects.create(**validated_data)