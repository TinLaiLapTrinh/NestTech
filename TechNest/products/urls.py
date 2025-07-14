
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
route = DefaultRouter()
route.register("list_product", views.ProductViewSet,basename="product")
route.register("products", views.CreateCompleteProductViewSet,  basename="product-with-all-component")
route.register('category',views.CategoryViewSet,basename='category')



urlpatterns = [
    path("",include(route.urls))
]