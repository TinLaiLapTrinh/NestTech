from django.urls import include, path
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register("shoppingcart", views.ShoppingCartViewSet,basename='shopping-cart')
router.register("order",views.OrderViewSet,basename='order')
router.register("order-detail",views.OrderDetailViewSet,basename='order-detail')
urlpatterns = [
    path('',include(router.urls)),
    path("payment/vnpay-return/", views.vnpay_return, name="vnpay-return"),
]