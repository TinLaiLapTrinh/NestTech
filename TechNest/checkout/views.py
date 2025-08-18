from django.shortcuts import render
from rest_framework import mixins, parsers, status, viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from accounts.perm  import IsCustomer
from checkout.perms import IsShoppingCartOwner
from .models import ShoppingCart, ShoppingCartItem
from .serializers import ShoppingCartItemSerializer, ShoppingCartListItemSerializer, ShoppingCartSerializer
from .paginators import ShoppingCartItemPaginator



class ShoppingCartViewSet(viewsets.GenericViewSet,
                          mixins.CreateModelMixin):
    pagination_class = ShoppingCartItemPaginator
    serializer_class = ShoppingCartSerializer

    def get_queryset(self):
        if getattr(self, 'swagger_fake_view', False):
            return ShoppingCart.objects.none()
        user = self.request.user
        return ShoppingCartItem.objects.filter(shopping_cart__owner=self.request.user)
    
    def get_cart(self):
        cart, _ = ShoppingCart.objects.get_or_create(owner=self.request.user)
        return cart
    
    def get_serializer_class(self):
        if getattr(self, 'swagger_fake_view', False):
            return ShoppingCartSerializer 
        if self.action == 'create':
            return ShoppingCartSerializer
        elif self.action == 'list_items':
            return ShoppingCartListItemSerializer
        elif self.action in ['add_item','update_item']:
            return ShoppingCartItemSerializer
        return super().get_serializer_class()

    def get_permissions(self):
        if self.action == 'create':
            return [IsCustomer()]
        elif self.action in ['update_item', 'add_item', 'list_items']:
            return [IsShoppingCartOwner()]
        raise PermissionDenied("Bạn không có quyền truy cập hành động này.")

    def perform_create(self, serializer):
        cart, _ = ShoppingCart.objects.get_or_create(owner=self.request.user)
        serializer.save(cart=cart)
    
    @action(detail=False, methods=['get'], url_path='items')
    def list_items(self, request):
        """Lấy danh sách item trong giỏ hàng"""
        items = self.get_queryset()  # vì get_queryset đã filter theo user
        page = self.paginate_queryset(items)
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)

    @action(detail=False, methods=['post'], url_path='add-item')
    def add_item(self, request):
        cart = self.get_cart()
        serializer = self.get_serializer(
            data=request.data,
            context={'request': request, 'cart': cart}  
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    @action(detail=False, methods=['patch'], url_path='update-item/(?P<item_id>[^/.]+)')
    def update_item(self, request, item_id=None):
        """Cập nhật số lượng item (tăng/giảm)"""
        cart = self.get_cart()
        try:
            item = cart.shopping_cart_item.get(pk=item_id)
        except ShoppingCartItem.DoesNotExist:
            return Response({'error': 'Item không tồn tại'}, status=404)

        serializer = self.get_serializer(item, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
    
    @action(detail=False, methods=['delete'], url_path='delete-item/(?P<item_id>[^/.]+)')
    def delete_item(self, request, item_id=None):
        """Xóa sản phẩm ra khỏi giỏ hàng"""
        cart = self.get_cart()
        try:
            item = cart.shopping_cart_item.get(pk=item_id)
        except ShoppingCartItem.DoesNotExist:
            return Response({'error': 'Item không tồn tại'}, status=404)

        item.delete()
        return Response({'message': 'Xóa sản phẩm thành công'}, status=204)