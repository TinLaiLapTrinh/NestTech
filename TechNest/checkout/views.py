from django.shortcuts import render
from django.conf import settings
from rest_framework.views import APIView
from rest_framework import mixins, parsers, status, viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.decorators import action
from django.utils.decorators import method_decorator
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated,AllowAny
from django.views.decorators.csrf import csrf_exempt
from utils.tasks import check_spam_rate
from utils.checker import check_spam

from django.http import HttpResponse
from accounts.perms  import IsCustomer, IsSupplier, IsDeliveryPerson
from utils.choice import UserType
from checkout.perms import IsShoppingCartOwner, IsOrderDetailOwner, IsOrderOwner,IsDeliveryPersonOrder, IsOrderRequest
from .models import ShoppingCart, ShoppingCartItem, Order, OrderDetail
from .serializers import (ShoppingCartItemSerializer, ShoppingCartListItemSerializer,
                           ShoppingCartSerializer,OrderSerializer,
                           OrderDetailSerializer,OrderListSerializer,
                             OrderRequestSerializer, OrderDetailConfirmImageSerializer,
                             RateSerializer)
from utils.choice import DeliveryStatus
from utils.vnpay import VNPay
import requests
from time import time
from datetime import datetime
import json
import hmac
import hashlib
import uuid
import urllib.parse
import urllib.request
from .paginators import ShoppingCartItemPaginator, OrderDetailItemPaginator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.http import JsonResponse
from django.conf import settings
from .models import Order, PaymentStatus, PaymentMethod


AKISMET_API_KEY = "68405bed0dbc"
BLOG_URL = "127.0.0.1:8000"

def check_spam_with_akismet(rate):
    data = {
        "blog": BLOG_URL,
        "user_ip": rate.ip_address,
        "user_agent": "Django/RestFramework",
        "comment_type": "review",
        "comment_author": rate.owner.username,
        "comment_content": rate.content
    }
    response = requests.post(
        f"https://{AKISMET_API_KEY}.rest.akismet.com/1.1/comment-check",
        data=data
    )
    is_spam = response.text.lower() == "true"
    print(f"Review ID {rate.id} spam check result: {is_spam}, value {rate.content}")
    return is_spam

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
    
class OrderDetailViewSet(viewsets.GenericViewSet,mixins.RetrieveModelMixin, mixins.ListModelMixin, mixins.UpdateModelMixin):
    pagination_class = OrderDetailItemPaginator

    def get_permissions(self):
        if self.action in ["update", "partial_update"]:
            return [(IsOrderRequest | IsDeliveryPerson)()]
        if self.action == 'upload_confirm_img':
            return [IsDeliveryPerson()]
        if self.action == 'rate_product':
            return[IsOrderDetailOwner()]
        return [AllowAny()]
    
    def get_serializer_class(self):
        if self.action in ['update','partial_update','list']:
            return OrderDetailSerializer    
        if self.action == 'upload_confirm_img':
            return OrderDetailConfirmImageSerializer 
        if self.action == 'rate_product':
            return RateSerializer
            
        return OrderRequestSerializer
    
    def get_queryset(self):
        if getattr(self, 'swagger_fake_view', False):
            return OrderDetail.objects.none()

        user = self.request.user

        if user.user_type == UserType.SUPPLIER:
            
            return OrderDetail.objects.filter(product__product__owner=user)

        if user.user_type == UserType.DELIVER_PERSON:
            
            return OrderDetail.objects.filter(delivery_person=user)
        
        if user.user_type == UserType.CUSTOMER:

            return OrderDetail.objects.filter(order__owner=user)


        return OrderDetail.objects.none()

    def list(self, request):
        search = request.query_params.get("search")
        delivery_status = request.query_params.get("delivery_status")
        
        queryset = self.get_queryset().select_related('product', 'order')
        if delivery_status:
            queryset = queryset.filter(
                delivery_status = delivery_status
            )
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def update(self, request, *args, **kwargs):
        print("VIEWSET UPDATE:", request.data)
        response = super().update(request, *args, **kwargs)
        print("VIEWSET RESPONSE:", response.data)
        return response

    @action(detail=True, methods=['post'], url_path='delivered')
    def upload_confirm_img(self, request, pk=None):
        order_detail = self.get_object()

        serializer = OrderDetailConfirmImageSerializer(
            data=request.data,
            context={"order": order_detail}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save(order=order_detail)

        return Response(
            {
                "message": "Xác nhận giao hàng thành công!",
                "order": OrderDetailSerializer(order_detail).data
            },
            status=status.HTTP_201_CREATED
        )
    @action(detail=True, methods=['post'], url_path='rate-product')
    def rate_product(self, request, pk=None):
        order_detail = self.get_object()

        if hasattr(order_detail, "rate"):
            return Response(
                {"message": "Đơn hàng này đã được đánh giá rồi."},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        rate = serializer.save(
            order_detail=order_detail,
            product=order_detail.product.product, 
            owner=request.user,
            ip_address=request.META.get('REMOTE_ADDR')
        )

        is_spam = check_spam_with_akismet(rate)
        rate.is_spam = is_spam
        rate.save(update_fields=["is_spam"])
        rate.save()

        return Response(
            {
                "message": "Đánh giá thành công!",
                "rate": RateSerializer(rate).data
            },
            status=status.HTTP_201_CREATED
        )

    
class OrderViewSet(viewsets.GenericViewSet,
                   mixins.ListModelMixin, 
                   mixins.CreateModelMixin,
                   mixins.RetrieveModelMixin):
    serializer_class = OrderSerializer

    def get_queryset(self):
        if getattr(self, 'swagger_fake_view', False):
            return Order.objects.none()
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
        print(self.request.data)
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


        if detail.status in [DeliveryStatus.DELIVERED, DeliveryStatus.REFUNDED]:
            return Response({'error': 'Đơn hàng đã hoàn tất, không thể hủy.'},
                            status=status.HTTP_400_BAD_REQUEST)

        detail.status = DeliveryStatus.CANCELLED
        detail.save()

        return Response({'message': 'Đơn hàng đã được hủy thành công',
                        'detail_id': detail.id,
                        'status': detail.status},
                        status=status.HTTP_200_OK)
    
    @action(detail=True, methods=["post"], url_path="pay-vnpay")
    def pay_vnpay(self, request, pk=None):
        """
        Tạo link thanh toán VNPAY cho order có id=pk
        """
        order = self.get_object()
        vnp = VNPay()

        vnp.requestData['vnp_Version'] = '2.1.0'
        vnp.requestData['vnp_Command'] = 'pay'
        vnp.requestData['vnp_TmnCode'] = settings.VNPAY_TMN_CODE
        vnp.requestData['vnp_Amount'] = int(order.total) * 100
        vnp.requestData['vnp_CurrCode'] = 'VND'
        vnp.requestData['vnp_TxnRef'] = str(order.id)
        vnp.requestData['vnp_OrderInfo'] = f"Thanh toán đơn hàng #{order.id}"
        vnp.requestData['vnp_OrderType'] = 'other'
        vnp.requestData['vnp_Locale'] = 'vn'
        vnp.requestData['vnp_CreateDate'] = datetime.now().strftime('%Y%m%d%H%M%S')
        vnp.requestData['vnp_IpAddr'] = request.META.get('REMOTE_ADDR', '127.0.0.1')
        vnp.requestData['vnp_ReturnUrl'] = settings.VNPAY_RETURN_URL  # URL gọi lại đây

        payment_url = vnp.get_payment_url(settings.VNPAY_PAYMENT_URL, settings.VNPAY_HASH_SECRET_KEY)


        order.payment_method = "vnpay"
        order.payment_status = "pending"
        order.save(update_fields=['payment_method', 'payment_status'])

        return Response({"pay_url": payment_url}, status=200)

@csrf_exempt
@api_view(['GET'])
def vnpay_return(request):
    """
    Callback VNPAY: cập nhật trạng thái thanh toán dựa trên vnp_TxnRef
    """
    
    print(f"data trả về: {request.GET.dict()}")
    inputData = request.GET.dict()
    vnp = VNPay()
    vnp.responseData = inputData

    order_id = inputData.get('vnp_TxnRef')
    if not order_id:
        return Response({'message': 'missing order id'}, status=400)

    try:
        order = Order.objects.get(id=order_id)
    except Order.DoesNotExist:
        return Response({'message': 'Order no exist'}, status=404)
    raw_query_string = request.META['QUERY_STRING']

    response_code = inputData.get('vnp_ResponseCode')
    order.payment_status = "paid" if response_code == "00" else "failed"
    order.save(update_fields=['payment_status'])
    return Response({
        'message': 'Success',
        'order_id': order.id,
        'payment_status': order.payment_status
    })