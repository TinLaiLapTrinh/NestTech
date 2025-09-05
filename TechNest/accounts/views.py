from django.shortcuts import render
from rest_framework.permissions import IsAuthenticated
from rest_framework import viewsets, generics, status, parsers, permissions
from .models import User, Follow
from . import serializers
from accounts.perms import IsFollower, IsCustomer
from utils.choice import UserType
from django.db.models import Q
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import FcmToken

class UserViewSet(viewsets.ViewSet, generics.ListAPIView):
    queryset = User.objects.filter(is_active=True)
    serializer_class = serializers.UserSerializer
    parser_classes = [parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser]

    def get_permissions(self):
        if self.action in ["get_current_user"]:
            return [permissions.IsAuthenticated()]

        return [permissions.AllowAny()]
    
    def get_serializer_class(self):
        if self.action in ["supplier_register"]:
            return serializers.SupplierRegister
        if self.action in ["customer_register"]:
            return serializers.CustomerRegister

        return super().get_serializer_class()
    
    @action(methods=["get"], detail=False, url_path="current-user")
    def get_current_user(self, request):
        user = request.user
        return Response(self.get_serializer(user).data)
    
    @action(methods=["post"],detail=False,url_path="customer-register")
    def customer_register(self,request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    @action(methods=["post"],detail=False, url_path="supplier-register")
    def supplier_register(self,request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class FollowViewSet(viewsets.GenericViewSet):
    serializer_class = serializers.FollowSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action == "unfollow":
            return [IsFollower(), IsCustomer()]  
        return [IsAuthenticated()]

    def get_queryset(self):
        """Trả về tất cả Follow liên quan đến user hiện tại"""
        if getattr(self, 'swagger_fake_view', False):
            return Follow.objects.none()
        user = self.request.user
        return Follow.objects.filter(Q(follower=user) | Q(followee=user))

    @action(detail=True, methods=["post"], url_path="follow")
    def follow(self, request, pk=None):
        """Follow một user"""
        followee = get_object_or_404(User, pk=pk)

        serializer = self.get_serializer(
            data={}, 
            context={"request": request, "followee": followee}
        )
        serializer.is_valid(raise_exception=True)
        follow = serializer.save()

        return Response(self.get_serializer(follow).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["delete"], url_path="unfollow")
    def unfollow(self, request, pk=None):
        """Unfollow một user"""
        followee = get_object_or_404(User, pk=pk)
        follow = Follow.objects.filter(follower=request.user, followee=followee).first()

        if not follow:
            return Response(
                {"detail": "Bạn chưa follow user này."},
                status=status.HTTP_404_NOT_FOUND
            )

        follow.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=["get"], url_path="is-following")
    def is_following(self, request, pk=None):
        """Check bạn có đang follow user này không"""
        followee = get_object_or_404(User, pk=pk)
        is_following = Follow.objects.filter(
            follower=request.user, followee=followee
        ).exists()
        return Response({"is_following": is_following})

    @action(detail=False, methods=["get"], url_path="followers")
    def followers(self, request):
        """Danh sách người đang follow bạn"""
        follows = Follow.objects.filter(followee=request.user)
        serializer = self.get_serializer(follows, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"], url_path="followings")
    def following(self, request):
        """Danh sách bạn đang follow"""
        follows = Follow.objects.filter(follower=request.user)
        serializer = self.get_serializer(follows, many=True)
        return Response(serializer.data)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def save_fcm_token(request):
    token = request.data.get("token")
    if not token:
        return Response({"error": "No token provided"}, status=400)
    print(f"{request.data} - {request.user.id}")
    # Lấy hoặc tạo token
    fcm_token_obj, created = FcmToken.objects.get_or_create(token=token)
    
    # Gắn user hiện tại vào token nếu chưa có
    if not fcm_token_obj.users.filter(id=request.user.id).exists():
        fcm_token_obj.users.add(request.user)
    
    return Response({"status": "Token saved"})