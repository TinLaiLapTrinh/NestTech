from rest_framework import permissions
from utils.choice import UserType

class IsSupplier(permissions.IsAuthenticated):
    """
    Chỉ cho phép người dùng có loại là `SUPPLIER` truy cập.
    """

    message = "Chỉ người dùng loại 'người bán hàng' mới được phép thực hiện thao tác này!"

    def has_permission(self, request, view):
        is_authenticated = super().has_permission(request, view)
        return is_authenticated and request.user.user_type == UserType.SUPPLIER 
    
class IsCustomer(permissions.IsAuthenticated):
    """
    Chỉ cho phép người dùng có loại là `CUSTOMER` truy cập.
    """

    message = "Chỉ người dùng loại 'người mua hàng' mới được phép thực hiện thao tác này!"

    def has_permission(self, request, view):
        is_authenticated = super().has_permission(request, view)
        return is_authenticated and request.user.user_type == UserType.CUSTOMER 
    
class IsDeliveryPerson(permissions.IsAuthenticated):
    """
    Chỉ cho phép người dùng có loại là `DELIVERY MAN` truy cập.
    """

    message = "Chỉ người dùng loại 'người mua hàng' mới được phép thực hiện thao tác này!"

    def has_permission(self, request, view):
        is_authenticated = super().has_permission(request, view)
        return is_authenticated and request.user.user_type == UserType.DELIVER_PERSON
    
class IsFollower(permissions.IsAuthenticated):
    """
    Chỉ cho phép người dùng là follower của bản ghi Follow được xóa.
    """
    def has_object_permission(self, request, view, obj):
        
        return obj.follower == request.user