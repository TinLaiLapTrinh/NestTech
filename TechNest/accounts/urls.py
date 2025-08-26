from django.urls import include, path
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register("users", views.UserViewSet,basename="user")
router.register("follow",views.FollowViewSet,basename="follow")

urlpatterns = [
    path("", include(router.urls)),
]