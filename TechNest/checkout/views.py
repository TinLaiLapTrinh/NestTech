from django.shortcuts import render
from rest_framework import mixins, parsers, status, viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated,AllowAny
from accounts.perms  import IsCustomer
from checkout.perms import IsShoppingCartOwner, IsOrderOwner
from .models import ShoppingCart, ShoppingCartItem, Order, OrderDetail
from .serializers import (ShoppingCartItemSerializer, ShoppingCartListItemSerializer,
                           ShoppingCartSerializer,OrderSerializer,
                           OrderDetailSerializer,OrderListSerializer)
from utils.choice import DeliveryStatus

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

        items = self.get_queryset()  
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
            return Response({'error': 'Item không tồn tại'}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(
            item, 
            data=request.data, 
            partial=True, 
            context={'cart': cart}
        )

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
            return Response({'error': 'Item không tồn tại'}, status=status.HTTP_404_NOT_FOUND)

        item.delete()
        return Response({'message': 'Xóa sản phẩm thành công'}, status=status.HTTP_204_NO_CONTENT)
    
class OrderViewSet(viewsets.GenericViewSet,
                   mixins.ListModelMixin, 
                   mixins.CreateModelMixin,
                   mixins.RetrieveModelMixin):
    serializer_class = OrderSerializer

    def get_queryset(self):
        user = self.request.user
        
        return Order.objects.filter(owner=user)


    def get_serializer_class(self):
        if self.action in ['retrieve']:
            return OrderSerializer
        elif self.action in ['list']:
            return OrderListSerializer
        return OrderSerializer

    def get_permissions(self):
        if self.action == 'create':
            return [IsCustomer()]
        if self.action == 'cancel_detail_order':
            return [IsOrderOwner()]
        return [AllowAny()]

    def perform_create(self, serializer):
        """Hook để gắn owner cho order"""
        serializer.save(owner=self.request.user)

    def create(self, request, *args, **kwargs):
        """Custom response JSON"""
        serializer = self.get_serializer(
            data=request.data,
            context={'owner': request.user}  
            )
        serializer.is_valid(raise_exception=True)
        order = self.perform_create(serializer)
        return Response(
            {"message": "order created successfully!", "order_id": serializer.instance.id},
            status=status.HTTP_201_CREATED
        )
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)



    @action(detail=True, methods=['patch'], url_path='cancel-order-detail/(?P<order_detail_id>[^/.]+)')
    def cancel_detail_order(self, request, pk=None, order_detail_id=None):
        order = self.get_object()
        try:
            detail = order.order_details.get(pk=order_detail_id)
        except OrderDetail.DoesNotExist:
            return Response({'error': 'Chi tiết đơn hàng không tồn tại'},
                            status=status.HTTP_404_NOT_FOUND)

        # Nếu đã giao xong thì không cho hủy
        if detail.status in [DeliveryStatus.DELIVERED, DeliveryStatus.REFUNDED]:
            return Response({'error': 'Đơn hàng đã hoàn tất, không thể hủy.'},
                            status=status.HTTP_400_BAD_REQUEST)

        detail.status = DeliveryStatus.CANCELLED
        detail.save()

        return Response({'message': 'Đơn hàng đã được hủy thành công',
                        'detail_id': detail.id,
                        'status': detail.status},
                        status=status.HTTP_200_OK)
