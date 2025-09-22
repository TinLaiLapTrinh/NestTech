from django.urls import include, path
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register("users", views.UserViewSet,basename="user")
router.register("follow",views.FollowViewSet,basename="follow")

urlpatterns = [
    path("", include(router.urls)),
    path('save-fcm-token/', views.save_fcm_token, name='save_fcm_token'),
    path("verify-cccd/", views.VerifyCCCDView.as_view(), name="verify-cccd"),
]