from django.shortcuts import render, get_object_or_404
from django.db.models import Avg, Count
from rest_framework.permissions import IsAuthenticated,AllowAny
from rest_framework.decorators import action
from accounts.perms import IsSupplier
import products.perms as perms 
from rest_framework import mixins, parsers, status, viewsets
from rest_framework import viewsets, generics, status, parsers, permissions
from .models import (Product,ProductImage,ProductStatus,
                    ProductVariant,Option,OptionValue,
                    VariantOptionValue)
from checkout.models import OrderDetail
from .serializers import (CategorySerializer,
                        ProductSerializer,
                        ProductListSerializer,
                        ProductVariantGetSerializer,
                        ProductVariantUpdateSerializer,
                        VariantGeneratorSerializer,
                        ProductVariantGetComponentSerializer,
                        ProductOptionSerializer,
                        OptionGetSerializer,
                        OptionSerializer,
                        ProductOptionSetupSerializer,
                        OptionValueGetSerializer,
                        OptionValueSerializer,
                        ProductVariantSerializer,
                        ProductListSerializer,
                        ProductDetailSerializer,
                        )
from checkout.serializers import RateSerializer
from .models import Category
from rest_framework.response import Response
from django.db.models import Q
from .paginators import ProductPaginator


class CategoryViewSet(viewsets.ViewSet, generics.ListAPIView, generics.RetrieveAPIView):
    queryset = Category.objects.all()

    serializer_class = CategorySerializer
    # def get_serializer_class(self):
    #     if self.action == 'retrieve':
    #         return CategoryDetailSerializer
    #     return CategoryListSerializer

class OptionViewSet(viewsets.ReadOnlyModelViewSet):  
    queryset = Option.objects.all()
    serializer_class = OptionGetSerializer
    permission_classes = [permissions.AllowAny]  

class OptionValueViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = OptionValue.objects.all()
    serializer_class = OptionValueGetSerializer
    permission_classes = [permissions.AllowAny]




class ProductViewSet(viewsets.GenericViewSet,
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.DestroyModelMixin,
    mixins.UpdateModelMixin,
    ):
    parser_classes = [parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser]
    pagination_class = ProductPaginator

    def get_queryset(self):
        return (
            Product.objects
            .filter(active=True, is_deleted=False)
            .annotate(
                rate_count=Count("rates", filter=Q(rates__is_spam=False), distinct=True),
                rate_avg=Avg("rates__rate", filter=Q(rates__is_spam=False))
            )
        )

    def get_serializer_class(self):
        if self.action in ['create','update', 'partial_update']:
            return ProductSerializer
        elif self.action == 'option_setup':
            return ProductOptionSetupSerializer
        
        elif self.action == 'add_variant':
            return ProductVariantSerializer
        elif self.action=='get_options':
            return ProductOptionSerializer
        elif self.action in ['my_products','list','deleted_products','shop_products']:
            return ProductListSerializer
        elif self.action =='retrieve':
            return ProductDetailSerializer
        
        return ProductSerializer  

    def get_permissions(self):
        if(self.action in ["create"]):
            return [IsSupplier()]
        elif(self.action in["add_variant","update","partial_update","destroy","add_option","generate_varaint"]):
            return[perms.IsProductOwner()]
        return [AllowAny()]
    
    def list(self, request):
        search = request.query_params.get("search")
        category_id = request.query_params.get("category")

        queryset = self.get_queryset().select_related('category', 'owner')

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

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def create(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            product = serializer.save(owner=request.user)
            return Response(    
                {"message": "Product created successfully!", "product_id": product.id},
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()

        data = request.data.copy()
        if 'owner' in data:
            data.pop('owner')

        serializer = self.get_serializer(instance, data=data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data)
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_deleted = True
        instance.active = False
        instance.save(update_fields=["is_deleted", "active"])
        return Response({"message": "Product soft deleted successfully!"}, status=status.HTTP_200_OK)
    
    def retrieve(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        product = get_object_or_404(queryset, pk=kwargs.get("pk"))
        serializer = self.get_serializer(product)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'], url_path='option-setup')
    def option_setup(self, request, pk=None):
        try:
            product = self.get_object()
        except:
            return Response({"detail": "Product not found"}, status=status.HTTP_404_NOT_FOUND)
        serializer = self.get_serializer(data=request.data, context={'product': product})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"message": "Option added successfully!"}, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'], url_path="generate-variant")
    def generate_variant(self, request, pk=None):
        serializer = VariantGeneratorSerializer(data={"product_id": pk})
        serializer.is_valid(raise_exception=True)
        variants = serializer.save()
        return Response(ProductVariantSerializer(variants, many=True).data)
    

    @action(detail=True, methods=['post'], url_path='bulk-add-variant')
    def bulk_add_variant(self, request, pk=None):
        """
        
        """
        try:
            product = self.get_object()
        except Product.DoesNotExist:
            return Response({"detail": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

        variants_data = request.data.get("variants", [])
        print(product.id)
        serializer = ProductVariantSerializer(
            data=variants_data,
            many=True,
            context={"product": product} 
        )
        serializer.is_valid(raise_exception=True)
        variants = serializer.save()

        return Response(
            {
                "message": f"{len(variants)} variants added successfully!",
                "variants": ProductVariantSerializer(variants, many=True).data
            },
            status=status.HTTP_201_CREATED
        )
    
    @action(detail=True, methods=['post'], url_path='add-variant')
    def add_variant(self,request,pk=None):
        try:
            product = self.get_object()
        except Product.DoesNotExist:
            return Response({"detail": "Product not found"}, status=status.HTTP_404_NOT_FOUND)
        print(request.data)

        serializer = self.get_serializer(data=request.data, context={'product': product})
        if serializer.is_valid():
            variant = serializer.save()
            return Response({"message": "Variant added successfully!", "variant_id": variant.id}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
      
    @action(detail=True, methods=['get'], url_path='get-options')
    def get_options(self, request, pk=None):
        product = self.get_object()
        
        options = product.product_options.all()  # giả sử Product có quan hệ ManyToMany đến ProductOption
        serializer = ProductOptionSerializer(options, many=True)
        
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    
    @action(detail=False, methods=['get'], url_path='deleted')
    def deleted_products(self, request):
        product_owner = request.user
        deleted_products = Product.objects.filter(is_deleted=True, owner=product_owner)
        page = self.paginate_queryset(deleted_products)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(deleted_products, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'],url_path='my-product')
    def my_products(self,request):
        product_owner = request.user
        products = Product.objects.filter(is_deleted=False, owner=product_owner)
        page = self.paginate_queryset(products)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'], url_path=r'shop-products/(?P<shop_id>\d+)')
    def shop_products(self, request, shop_id=None):
        products = Product.objects.filter(is_deleted=False, owner_id=shop_id)
        page = self.paginate_queryset(products)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['get'], url_path='rates')
    def get_rate(self, request, pk=None):
        product = self.get_object()


        rates = product.rates.select_related("owner", "order_detail").all()


        page = self.paginate_queryset(rates)
        if page is not None:
            serializer = RateSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = RateSerializer(rates, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    

class ProductVariantViewSet(viewsets.GenericViewSet,
                              mixins.ListModelMixin,          
                              mixins.RetrieveModelMixin,
                              mixins.UpdateModelMixin,
                              mixins.DestroyModelMixin):
    
    def get_queryset(self):
        product_id = self.kwargs.get('product_pk') 
        return ProductVariant.objects.filter(product_id=product_id, active=True)

    def get_permissions(self):
        if self.action in ['update', 'partial_update', 'destroy']:
            return [perms.IsVariantOwner()]
        return [AllowAny()]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProductVariantGetSerializer
        elif self.action == 'list':
            return ProductVariantGetComponentSerializer
        elif self.action =='update':
            return ProductVariantUpdateSerializer

    def update(self, request, *args, **kwargs):
        # request.data đã chứa dữ liệu từ form data
        response = super().update(request, *args, **kwargs)
        return Response({
            "message": "Product variant updated successfully!",
            "data": response.data
        }, status=status.HTTP_200_OK)

    def destroy(self, request, *args, **kwargs):
        response = super().destroy(request, *args, **kwargs)
        return Response({
            "message": "Product variant deleted successfully!",
            "data": response.data
        }, status=status.HTTP_200_OK)
    
