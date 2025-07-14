from django.urls import include, path
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()

# Register the viewsets with the router
router.register("provinces", viewset=views.ProvinceViewSet, basename="province")
router.register("districts", viewset=views.DistrictViewSet, basename="district")
router.register("wards", viewset=views.WardViewSet, basename="ward")

urlpatterns = [
    path("", include(router.urls)),
]
