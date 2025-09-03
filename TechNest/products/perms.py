from rest_framework import permissions
from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import BasePermission
from rest_framework.exceptions import PermissionDenied
from products.models import Option, OptionValue, ProductVariant, VariantOptionValue, Product


class IsProductOwner(IsAuthenticated):
    def has_object_permission(self, request, view, product_object):
        is_authenticated = super().has_permission(request, view)
        return is_authenticated and product_object.owner == request.user
    
class IsVariantOwner(IsAuthenticated):
    def has_object_permission(self, request, view, obj):
        is_authenticated = super().has_permission(request,view)
        return is_authenticated and obj.product.owner == request.user
    

