from rest_framework import permissions
from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import BasePermission
from rest_framework.exceptions import PermissionDenied
from products.models import Option, OptionValue, ProductVariant, VariantOptionValue, Product


class IsProductOwner(IsAuthenticated):
    def has_object_permission(self, request, view, product_object):
        is_authenticated = super().has_permission(request, view)
        return is_authenticated and product_object.owner == request.user
    
class IsVariantOwner(permissions.IsAuthenticated):
    def has_object_permission(self, request, view, obj):
        is_authenticated = super().has_permission(request,view)
        return is_authenticated and obj.product.owner == request.user


# class IsRelatedToOwnedProduct(BasePermission):
#     # Không cần __init__, dùng class attribute ở subclass

#     def has_permission(self, request, view):
#         if request.method in permissions.SAFE_METHODS:
#             return True

#         # Lấy model và path từ subclass (hoặc từ view nếu cần fallback)
#         model = getattr(self, 'lookup_model', None) or getattr(view, 'lookup_model', None)
#         product_path = getattr(self, 'product_path', None) or getattr(view, 'product_path', None)

#         pk = view.kwargs.get("pk")
#         print("🔍 PK:", pk)
#         print("🔍 USER:", request.user.id)

#         if not model or not pk or not product_path:
#             print("❌ Thiếu lookup_model hoặc product_path")
#             return False

#         try:
#             instance = model.objects.get(pk=pk)
#             product = self.deep_getattr(instance, product_path)
#             print("✅ Lấy được product:", product)
#         except Exception as e:
#             print("❌ Lỗi khi truy cập product:", e)
#             return False

#         return getattr(product, "owner", None) == request.user

#     def deep_getattr(self, obj, attr_path):
#         for attr in attr_path.split("."):
#             obj = getattr(obj, attr)
#         return obj


# # Dùng cho Option
# class IsOptionOwner(IsRelatedToOwnedProduct):
#     lookup_model = Product
#     product_path = ""

# # Dùng cho OptionValue (có option -> product)
# class IsOptionValueOwner(IsRelatedToOwnedProduct):
#     lookup_model = Option
#     product_path = "product"

# # Dùng cho ProductVariant
# class IsVariantOwner(IsRelatedToOwnedProduct):
#     lookup_model = ProductVariant
#     product_path = "product"

# # Dùng cho VariantOptionValue
# class IsVariantOptionValueOwner(IsRelatedToOwnedProduct):
#     lookup_model = VariantOptionValue
#     product_path = "product_variant.product"
