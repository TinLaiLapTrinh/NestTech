from rest_framework import serializers
from .models import User
from utils.choice import UserType


class UserSerializer(serializers.ModelSerializer):

    follow_count = serializers.SerializerMethodField()

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
            "follow_count",
            
        ]
        extra_kwargs = {"password": {"write_only": True}}

    def get_follow_count(self, obj):
        pass

    def create(self, validated_data):
        user = User(**validated_data)
        user.set_password(user.password)
        user.save()
        return user
    
class SupplierRegister(serializers.ModelSerializer):

    avatar = serializers.ImageField(required=False)
    
    

    

    
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
        user_serializer = UserSerializer(data = validated_data)
        if user_serializer.is_valid():
            return user_serializer.save(
                is_active = True,
                user_type = UserType.CUSTOMER
            )
        else:
            raise serializers.ValidationError(user_serializer.errors)


        