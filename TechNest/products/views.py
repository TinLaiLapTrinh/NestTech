from django.shortcuts import render
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from accounts.perm import IsSupplier
from .perm import IsProductOwner
from rest_framework import viewsets, generics, status, parsers, permissions
from .models import (Product,ProductCartItem
                    ,ProductImage,ProductStatus,
                    ProductVariant,Option,OptionValue,
                    VariantOptionValue)
from .serializers import (CategorySerializer,
                        ProductSerializer,
                        ProductWithComponentsSerializer,
                        ProductVariantGetSerializer,
                        ProductVariantCreateSerializer,
                        OptionCreateSerializer,
                        OptionGetSerializer,
                        OptionValueCreateSerializer,
                        VariantOptionValueCreateSerializer)
from .models import Category
from rest_framework.response import Response
from django.db.models import Q


class CategoryViewSet(viewsets.ViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

class ProductViewSet(viewsets.ViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer

    def list(self, request):
        search = request.query_params.get("search")
        category_id = request.query_params.get("category")

        queryset = self.queryset.select_related('category', 'owner')

        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) |
                Q(description__icontains=search) |
                Q(category__type__icontains=search) |
                Q(owner__first_name__icontains=search) |
                Q(owner__last_name__icontains=search)
            )

        if category_id:
            queryset = queryset.filter(category_id=category_id)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def create(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            product = serializer.save()
            return Response({"message": "Product created successfully!", "product_id": product.id}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


    
class CreateCompleteProductViewSet(viewsets.ViewSet):
    queryset = Product.objects.all()
    permission_classes = [IsSupplier,IsAuthenticated]
    def get_permissions(self):
        if self.action in ['create']:
            return [IsSupplier()]
        if self.action in ['create_option','create_option_value','variant_create']:
            return [IsProductOwner()]
        return [permissions.AllowAny()]
    def create(self, request):
        serializer = ProductWithComponentsSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            product = serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'], url_path='options')
    def create_option(self, request, pk=None):
        try:
            product = Product.objects.get(pk=pk, owner = request.user)
        except:
            return Response("Sản phẩm không tồn tại hoặc bạn không có quyền")
        serializer = OptionCreateSerializer(data=request.data, context={'product':product})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data,status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    @action(detail=True, methods=['post'], url_path='options/(?P<option_id>[^/.]+)/values')
    def create_option_value(self, request, pk=None, option_id=None):
        try:
            option = Option.objects.select_related("product").get(pk=option_id, product__pk=pk)
        except Option.DoesNotExist:
            return Response({"detail": "Không tìm thấy option thuộc sản phẩm."}, status=status.HTTP_404_NOT_FOUND)

        serializer = OptionValueCreateSerializer(data=request.data, context={'option': option})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'], url_path='add-variant')
    def variant_create(self, request, pk=None):
        try:
            product = Product.objects.get(pk=pk, owner=request.user)
        except Product.DoesNotExist:
            return Response({"detail": "Sản phẩm không tồn tại hoặc bạn không có quyền."}, status=status.HTTP_404_NOT_FOUND)

        variant_data = {
            "price": request.data.get("price"),
            "stock": request.data.get("stock"),
        }

        variant_serializer = ProductVariantCreateSerializer(data=variant_data, context={"product": product})
        if not variant_serializer.is_valid():
            return Response(variant_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        variant = variant_serializer.save()

        option_value_ids = request.data.get("option_values", [])
        if not isinstance(option_value_ids, list) or not option_value_ids:
            return Response({"option_values": "Danh sách option value không hợp lệ."}, status=status.HTTP_400_BAD_REQUEST)
        if not isinstance(option_value_ids, list) or not all(isinstance(i, int) for i in option_value_ids):
            return Response({"option_values": "Danh sách option value phải là list các số nguyên."}, status=status.HTTP_400_BAD_REQUEST)

        for option_value_id in option_value_ids:
            vov_data = {
                "product_variant": variant.id,
                "option_value": option_value_id
            }
            vov_serializer = VariantOptionValueCreateSerializer(data=vov_data)
            if not vov_serializer.is_valid():
                return Response(vov_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            vov_serializer.save()

        return Response({"message": "Tạo biến thể thành công."}, status=status.HTTP_201_CREATED)
    
# class OptionViewSet(viewsets.ViewSet, generics.GenericAPIView):
#     queryset = Option.objects.all()
#     serializer_class= OptionGetSerializer
#     def get_permissions(self):
#         if self.action in ["option_create"]:
#             return [perm.IsOptionOwner()]
#         return [permissions.AllowAny()]
#     @action(methods=['post'], detail=True, url_path='product_option_add')
#     def option_create(self, request, pk=None):
#             try:
#                 product = Product.objects.get(pk=pk, owner = request.user)
#             except:
#                 return Response("Sản phẩm không tồn tại hoặc bạn không có quyền")
#             serializer = OptionCreateSerializer(data=request.data, context={'product':product})
#             if serializer.is_valid():
#                 serializer.save()
#                 return Response(serializer.data,status=status.HTTP_201_CREATED)
#             return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
#     @action(methods=['get'], detail=True, url_path='product_option_get')
#     def option_get(self, request, pk=None):
#             product = Product.objects.get(pk=pk)
#             options = Option.objects.filter(product=product)
#             serializer = OptionGetSerializer(options, many=True)
#             return Response(serializer.data, status=status.HTTP_200_OK)  

# class OptionValueViewSet(viewsets.ViewSet, generics.GenericAPIView):
#     queryset = Option.objects.all()
#     serializer_class = OptionCreateSerializer
#     def get_permissions(self):
#         if self.action in ["create_option_value"]:
#             return [perm.IsOptionValueOwner()]
#         return [permissions.AllowAny()]

#     def get_object(self):
#         return Option.objects.get(pk=self.kwargs["pk"])

#     @action(methods=['post'], detail=True, url_path='option_value_add')
#     def option_value_create(self, request, pk=None):
#         try:
#             option = self.get_object()
#         except Option.DoesNotExist:
#             return Response({"detail": "Không tìm thấy option."}, status=status.HTTP_404_NOT_FOUND)

#         serializer = OptionValueCreateSerializer(data=request.data, context={'option': option})
#         if serializer.is_valid():
#             serializer.save()
#             return Response(serializer.data, status=status.HTTP_201_CREATED)
#         return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

#     @action(methods=['get'], detail=True, url_path='option_value_list')
#     def option_value_get(self, request, pk=None):
#         try:
#             option = self.get_object()
#         except Option.DoesNotExist:
#             return Response({"detail": "Không tìm thấy option."}, status=status.HTTP_404_NOT_FOUND)

#         option_values = option.option_value.all()  # related_name từ OptionValue
#         serializer = OptionValueCreateSerializer(option_values, many=True)
#         return Response(serializer.data, status=status.HTTP_200_OK)

            
# class VariantViewSet(viewsets.ViewSet,generics.GenericAPIView):
#     queryset= ProductVariant.objects.all()
#     serializer_class= ProductVariantGetSerializer
#     def get_permissions(self):
#         if self.action in ["variant_product_create"]:
#             return [perm.IsVariantOwner()]
#         return [permissions.AllowAny()]
#     @action(methods=['post'],detail=True,url_name='variant_add')
#     def variant_product_create(self,request,pk):
#         try:
#             product = Product.objects.get(pk=pk, owner=request.user)
#         except Product.DoesNotExist:
#             return Response({"detail": "Sản phẩm không tồn tại."}, status=status.HTTP_404_NOT_FOUND)
#         data = request.data

#         variant_data = {
#             "price": data.get("price"),
#             "stock": data.get("stock"),
#         }

#         variant_serializer = ProductVariantCreateSerializer(data=variant_data, context={"product": product})
#         if not variant_serializer.is_valid():
#             return Response(variant_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
#         variant = variant_serializer.save()

#         option_value_ids = data.get("option_values", [])
#         if not isinstance(option_value_ids, list) or not option_value_ids:
#             return Response({"option_values": "Danh sách option value không hợp lệ."}, status=status.HTTP_400_BAD_REQUEST)

#         for option_value_id in option_value_ids:
#             vov_serializer = VariantOptionValueCreateSerializer(data={
#                 "product_variant": variant.id,
#                 "option_value": option_value_id
#             })
#             if not vov_serializer.is_valid():
#                 return Response(vov_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
#             vov_serializer.save()

#         return Response({"message": "Tạo biến thể thành công."}, status=status.HTTP_201_CREATED)
    
#     @action(methods=['get'],detail=True,url_name='variant_list')
#     def variant_product_get(self,request,pk):
#         try:
#             product=Product.objects.get(pk=pk)
#         except not product:
#             return Response({"detail":" Sản phẩm không tồn tại."}, status=status.HTTP_404_NOT_FOUND)
#         options = product.options.all()
#         serializer = OptionGetSerializer(options, many=True)
#         return Response(serializer.data, status=status.HTTP_200_OK)
            
            
            
        