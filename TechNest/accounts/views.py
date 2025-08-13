from django.shortcuts import render
from rest_framework import viewsets, generics, status, parsers, permissions
from .models import User
from . import serializers
from rest_framework.decorators import action
from rest_framework.response import Response
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