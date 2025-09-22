from django.urls import include, path
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register("shoppingcart", views.ShoppingCartViewSet,basename='shopping-cart')
router.register("order",views.OrderViewSet,basename='order')
router.register("order-detail",views.OrderDetailViewSet,basename='order-detail')

urlpatterns = [
    path('',include(router.urls)),
    path('stats/', views.DashboardStatsView.as_view(), name="dashboard-stats"),
    path("payments/ipn/", views.momo_ipn, name="momo-ipn"),
    path("payments/return/", views.momo_return, name="momo-return"),
]