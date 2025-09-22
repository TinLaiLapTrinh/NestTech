from django.urls import path, include
from rest_framework.routers import DefaultRouter

from . import views
router = DefaultRouter()


router.register("products", views.ProductViewSet, basename="product")
router.register("category", views.CategoryViewSet, basename="category")



urlpatterns = [
    path("", include(router.urls)),
    path("product/<int:product_pk>/variant/", views.ProductVariantViewSet.as_view({'get': 'list'}), name="product-component-list"),
    path("product/<int:product_pk>/variant/<int:pk>/", views.ProductVariantViewSet.as_view({'get': 'retrieve', 'put': 'update', 'delete': 'destroy'}), name="product-component-detail"),
]
