from rest_framework import serializers, status
from rest_framework.exceptions import ValidationError
from utils.choice import UserType
from utils.serializers import ImageSerializer
from .models import Order,OrderDetail,ShoppingCart, ShoppingCartItem
from products.models import ProductVariant, Product, VariantOptionValue
from products.serializers import ProductVariantGetSerializer
from django.db import transaction
import json
from locations.models import Province,Ward
from rest_framework.response import Response

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
