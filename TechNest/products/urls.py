from django.urls import path, include
from rest_framework.routers import DefaultRouter
# from rest_framework_nested import routers
from . import views
router = DefaultRouter()


router.register("products", views.ProductViewSet, basename="product")
router.register("category", views.CategoryViewSet, basename="category")
# router.register(r"product", views.ProductComponentViewSet, basename="product-component")

# Nested router cho product-component
# product_router = routers.NestedDefaultRouter(router, "product", lookup="product")
# product_router.register("component", views.ProductComponentViewSet, basename="product-component")

urlpatterns = [
    path("", include(router.urls)),
    path("product/<int:product_pk>/variant/", views.ProductVariantViewSet.as_view({'get': 'list', 'post': 'create'}), name="product-component-list"),
    path("product/<int:product_pk>/variant/<int:pk>/", views.ProductVariantViewSet.as_view({'get': 'retrieve', 'put': 'update', 'delete': 'destroy'}), name="product-component-detail"),
]
