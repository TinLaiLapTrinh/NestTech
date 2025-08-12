from django.urls import include, path
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()

# Register the viewsets with the router
router.register("provinces", viewset=views.ProvinceViewSet, basename="province")

urlpatterns = [
    path("", include(router.urls)),
]
