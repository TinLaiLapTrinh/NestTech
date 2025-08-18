from django.urls import include, path
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register("shoppingcart", views.ShoppingCartViewSet,basename='shopping-cart')
urlpatterns = [
    path('',include(router.urls))
]