from django.shortcuts import render
from rest_framework.permissions import IsAuthenticated
from rest_framework import viewsets, generics, status, parsers, permissions
from .models import User, Follow,AuditLog
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
from rest_framework.views import APIView
from .verification.verification_api import hash_cccd, recognize_id_card, encrypt_cccd, decrypt_cccd
import requests
from django.db import IntegrityError


class UserViewSet(viewsets.ViewSet, generics.ListAPIView, generics.RetrieveAPIView):
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
        if self.action in ["get_current_user"]:
            return serializers.UserSerializer

        return super().get_serializer_class()
    
    @action(methods=["get"], detail=False, url_path="current-user")
    def get_current_user(self, request):
        user = request.user
        return Response(self.get_serializer(user).data)
    
    @action(methods=["post"],detail=False,url_path="customer-register")
    def customer_register(self,request):
        print(request.data)
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    @action(methods=["post"],detail=False, url_path="supplier-register")
    def supplier_register(self,request):
        print(request.data)
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        print(serializer.errors)
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
        print(follow.data)

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
    
    fcm_token_obj, created = FcmToken.objects.get_or_create(token=token)
    
    if not fcm_token_obj.users.filter(id=request.user.id).exists():
        fcm_token_obj.users.add(request.user)
    
    return Response({"status": "Token saved"})


class VerifyCCCDView(APIView):
    def post(self, request):
        user = request.user
        
        if user.user_type != UserType.SUPPLIER:
            return Response({"error": "User type does not require verification."}, status=400)

        image_file = request.FILES.get("image")
        if not image_file:
            return Response({"error": "Missing image"}, status=400)

        try:
            # OCR CCCD
            result = recognize_id_card(image_file)
            info_list = result.get("data", [])
            info = info_list[0] if info_list and isinstance(info_list, list) else {}

            # Kiểm tra các trường quan trọng
            verified = all(info.get(k) for k in ["id", "name", "dob"])
            cccd_data = {
                "id": info['id'],
                "name": info['name'],
                "dob": info['dob']
            }

            cccd_hash = hash_cccd(cccd_data)  


            enc_cccd = encrypt_cccd(cccd_data)  
            if AuditLog.objects.filter(cccd_hash=cccd_hash).exists():
                return Response({
                    "verified": verified,
                    "message": "Duplicate CCCD detected. Verification already recorded."
                }, status=status.HTTP_400_BAD_REQUEST)


            try:
                AuditLog.objects.create(
                    user=user,
                    cccd_hash=cccd_hash,       
                    cccd_enc=enc_cccd,   
                    verified=True
                )
                print(decrypt_cccd(enc_cccd))
            except IntegrityError:
                return Response({"error": "Duplicate CCCD detected."}, status=400)
            if verified:
                user.is_verified = True
                user.save()

            return Response({"verified": verified}, status=200)

        except requests.exceptions.RequestException as e:
            return Response({"error": f"FPT API error: {str(e)}"}, status=502)
