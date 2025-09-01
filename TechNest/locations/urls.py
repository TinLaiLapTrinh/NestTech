from django.urls import include, path
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()

# Register the viewsets with the router
router.register("locations", viewset=views.LocationViewSet, basename="location")
router.register("user-location", views.UserLocationViewSet,basename="user-location")
router.register("shipping-route", views.ShippingRouteViewSet, basename="shippingroute")
urlpatterns = [
    path("", include(router.urls)),
]
