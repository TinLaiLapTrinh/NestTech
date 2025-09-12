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
from .service.statistics import stats_for_supplier, stats_for_shipper  
from .spam_checker.spam_checker import check_spam 

from django.http import HttpResponse
from accounts.perms  import IsCustomer, IsSupplier, IsDeliveryPerson, IsSupplierOrDeliveryPerson
from utils.choice import UserType
from checkout.perms import IsShoppingCartOwner, IsOrderDetailOwner, IsOrderOwner,IsDeliveryPersonOrder, IsOrderRequest
from .models import ShoppingCart, ShoppingCartItem, Order, OrderDetail
from .serializers import (ShoppingCartItemSerializer, ShoppingCartListItemSerializer,
                           ShoppingCartSerializer,OrderSerializer,
                           OrderDetailSerializer,OrderListSerializer,
                             OrderRequestSerializer, OrderDetailConfirmImageSerializer,
                             RateSerializer)
from utils.choice import DeliveryStatus
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
from utils.momo_service import create_momo_payment, generate_qr_from_url


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
        if self.action in ['update','partial_update','list','retrieve']:
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

        try:
            results = check_spam([rate.content])   # lấy nội dung đánh giá để check
            task1_label = results[rate.content]["task1"]
            task2_label = results[rate.content]["task2"]


            is_spam = (task1_label == "spam") or (task2_label.startswith("spam"))
            rate.is_spam = is_spam
            print(f"Đánh giá rating là:{is_spam}")
            rate.save(update_fields=["is_spam"])
        except Exception as e:
            # Nếu có lỗi khi check spam, mặc định không đánh dấu spam
            print("Spam checker error:", str(e))
            rate.is_spam = False
            rate.save(update_fields=["is_spam"])
        # ================================================

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
        if self.action in ["cancel_detail_order", "get_payment_status"]:
            return [IsOrderOwner()]
        return [AllowAny()]

    def perform_create(self, serializer):

        return serializer.save(owner=self.request.user)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(
            data=request.data,
            context={'owner': request.user}
        )
        serializer.is_valid(raise_exception=True)
        order = self.perform_create(serializer)


        momo_response = create_momo_payment(
            amount=str(int(order.total)),
            order_id=order.id,  # truyền order.id thôi, hàm tự sinh unique
            order_info=f"Thanh toán đơn hàng {order.id}"
        )
        

        if momo_response.get("resultCode") == 0:
            pay_url = momo_response.get("payUrl")
            qr_code_base64 = generate_qr_from_url(pay_url)

        else:
            pay_url = None

        return Response(
            {
                "message": "Order created successfully!",
                "order_id": order.id,
                "payUrl": pay_url,
                "qrCodeImage":qr_code_base64,
                "momo_response": momo_response 
            },
            status=status.HTTP_201_CREATED
        )
    
    @action(detail=True, methods=['get'], url_path='payment-status')
    def get_payment_status(self,request,pk=None):
        order = self.get_object()
        return Response(
            {
                "payment_status":order.payment_status
            },
            status=status.HTTP_200_OK
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
    
@api_view(['POST'])
def momo_ipn(request):
    data = request.data
    order_id = data.get("orderId")  # ví dụ: "78_1757513847"
    result_code = data.get("resultCode")

    try:
        real_order_id = order_id.split("_")[0]  # lấy id gốc từ orderId
        order = Order.objects.get(id=real_order_id)
    except Order.DoesNotExist:
        return Response({"error": "Order not found"}, status=status.HTTP_404_NOT_FOUND)

    if result_code == 0:  # thanh toán thành công
        order.payment_status = PaymentStatus.PAID
        order.save()
    else:
        order.payment_status = PaymentStatus.FAILED
        order.save()

    return Response({"message": "IPN received"}, status=status.HTTP_200_OK)

@csrf_exempt
def momo_return(request):
    result_code = request.GET.get("resultCode")
    order_id = request.GET.get("orderId")
    message = request.GET.get("message")


    if result_code == "0":
        return HttpResponse(f"Thanh toán đơn hàng {order_id} thành công!")
    else:
        return HttpResponse(f"Thanh toán thất bại: {message}")
    

class DashboardStatsView(APIView):
    permission_classes = [IsSupplierOrDeliveryPerson]

    def get(self, request):
        user = request.user

        if user.user_type == UserType.SUPPLIER:
            data = stats_for_supplier(user)
        elif user.user_type == UserType.DELIVER_PERSON:
            data = stats_for_shipper(user)
        else:
            return Response(
                {"detail": "Chỉ SUPPLIER hoặc DELIVER_PERSON mới được phép."},
                status=403
            )

        return Response(data)