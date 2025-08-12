from django.forms.utils import mark_safe
from django.utils.html import format_html
from django.contrib import admin
from .models import User, SupplierApproved
from products.models import Product
from admin_site.site import technest_admin_site
from unfold.admin import ModelAdmin
from admin_site.components import action_button, option_display
from utils.choice import UserType, DeliveryMethods,ProductStatus
from django.shortcuts import redirect, get_object_or_404
from django.contrib import messages
from django.urls import path



class UserAdmin(ModelAdmin):
    """
    Trang quản lý người dùng
    """

    list_display = ["username", "is_active", "email", "user_type_display"]
    search_fields = ["username", "email"]
    list_filter = ["is_active", "date_joined"]
    sortable_by = ["username"]
    readonly_fields = ["avatar_view"]
    filter_horizontal = ["user_permissions"]

    fieldsets = [
        (
            "User profile",
            {"fields": ["is_active", "username", "email", "avatar_view"]},
        ),
        ("Location", {"fields": ["address", "province"]}),
        (
            "Permissions",
            {
                "description": "Config user permissions",
                "classes": ["collapse"],
                "fields": ["user_type", "user_permissions", "is_staff", "is_superuser"],
            },
        ),
    ]

    def avatar_view(self, user):
        if user:
            return mark_safe(f"<img src='{user.avatar.url}' width='200' />")

    def user_type_display(self, user: User):
        """Hiển thị loại tài khoản dưới dạng biểu tượng màu."""

        if user.is_superuser:
            return option_display("Admin", color="red")

        if user.user_type == UserType.SUPPLIER:
            return option_display("Supplier", color="purple")

        if user.user_type == UserType.CUSTOMER:
            return option_display("Customer", color="teal")

    user_type_display.short_description = "User Type"

class SupplierApprovedAdmin(UserAdmin):
    """
    Trang quản lý phê duyệt chủ trọ
    """
    list_display = ["username", "email", "product_name", "action_buttons"]
    actions = ["approve_user", "reject_user"]
    search_fields = ["username", "email"]
    list_filter = ["date_joined"]
    sortable_by = ["username"]

    fieldsets = [
        ("User profile", {"fields": ["username", "email", "avatar_view"]}),
        # ("Location", {"fields": ["address", "province"]}),
        (
            "Product Details",
            {"fields": ["product_name", "product_address", "product_image_gallery"]},
        ),
    ]
    def product_name(self, user):
        """
        Hiển thị thông tin tên dãy trọ đăng ký
        """
        product = user.products.first()
        if not product:
            return "No product registered"
        return product.name
    def product_address(self, user):

        product = user.products.first()
        if not product:
            return "No products registered"

        html = '<div style="margin-top: 10px;">'
        html += f"<p>{product.address}, {product.province}</p>"
        html += "</div>"
        return format_html(html)    
    def product_image_gallery(self, user):
        """
        Hiển thị chi tiết dãy trọ trong trang chi tiết của tài khoản
        """
        product = user.products.first()
        if not product:
            return "No product registered"

        html = '<div style="margin-top: 10px;">'
        for image in product.images.all():
            html += f"<img src='{image.image.url}' alt='{image.alt}' style='width: 150px; margin-right: 10px;' />"
        html += "</div>"
        return format_html(html)

    product_image_gallery.short_description = "product Image Gallery"
    

  
    def get_queryset(self, request):

        qs = super().get_queryset(request)

        return qs.filter(user_type=UserType.SUPPLIER,is_active=False).prefetch_related('products')

    def approve_user(self, request,user_id):
        user = get_object_or_404(User, id=user_id,user_type = UserType.SUPPLIER)
        product =  user.products.first()

        if product:
            product.status = Product = ProductStatus.APPROVED
            product.save()
        
        

        user.is_active=True
        user.save()
        messages.success(request, f"User {user.username} has been approved.")
        return redirect("/supplier-admin/accounts/supplierapproved/")
    
    def reject_user(self,request,user_id):
        user = get_object_or_404(User,id=user_id,user_type = UserType.SUPPLIER)

        user.delete()
        messages.success(request, f"User {user.username} has been rejected.")
        return redirect("/supplier-admin/accounts/supplierapproved/")
    def get_urls(self):
        urls = super().get_urls()
        custom_urls=[
            path("<int:user_id>/approve/",self.admin_site.admin_view(self.approve_user),name="approve_supplier"),
            path("<int:user_id>/reject/",self.admin_site.admin_view(self.reject_user),name="reject_supplier")
        ]
        return custom_urls + urls
    def action_buttons(self, user):
        """
        Thêm các nút hành động (Approve, Reject) vào danh sách
        """
        approve_url = f"/supplier-admin/accounts/supplierapproved/{user.id}/approve/"
        reject_url = f"/supplier-admin/accounts/supplierapproved/{user.id}/reject/"
        approve_button = action_button("Approve", approve_url, color="green")
        reject_button = action_button("Reject", reject_url, color="red")
        return mark_safe(f"{approve_button} {reject_button}")
    action_buttons.short_description = "Actions"

    def change_view(self, request, object_id, form_url="", extra_context=None):
        """
        Tùy chỉnh giao diện trang chi tiết để thêm nút Approve và Reject
        """
        extra_context = extra_context or {}
        user = self.get_object(request, object_id)
        if user:
            approve_url = f"/supplier-admin/accounts/supplierapproved/{user.id}/approve/"
            reject_url = f"/supplier-admin/accounts/supplierapproved/{user.id}/reject/"
            extra_context["custom_buttons"] = mark_safe(
                f"{action_button('Approve', approve_url, color='green')} "
                f"{action_button('Reject', reject_url, color='red')}"
            )

            extra_context["hide_default_buttons"] = True
        return super().change_view(request, object_id, form_url, extra_context)


    ### XOÁ CÁC CHỨC NĂNG: THÊM, XOÁ, SỬA TÀI KHOẢN ĐANG DUYỆT ###
    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False

technest_admin_site.register(SupplierApproved,SupplierApprovedAdmin)
technest_admin_site.register(User, UserAdmin)
