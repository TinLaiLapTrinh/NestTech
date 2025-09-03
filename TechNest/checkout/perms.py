from rest_framework import permissions
from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import BasePermission
from rest_framework.exceptions import PermissionDenied

class IsShoppingCartOwner(IsAuthenticated):
    def has_object_permission(self, request, view, cart_obj):
        is_authenticated = super().has_permission(request,view)
        return is_authenticated and cart_obj.owner == request.user
    
class IsOrderOwner(IsAuthenticated):
    def has_object_permission(self, request, view, order_obj):
        is_authenticated = super().has_permission(request,view)
        return is_authenticated and order_obj.owner == request.user
    
class IsOrderRequest(IsAuthenticated):
    def has_object_permission(self, request, view, obj):
        is_authenticated = super().has_permission(request,view)
        
        return is_authenticated and obj.product.product.owner == request.user
    
class IsDeliveryPerson(IsAuthenticated):
    def has_object_permission(self, request, view, obj):
        is_authenticated = super().has_permission(request,view)
        
        return is_authenticated and obj.delivery_person == request.user
    
