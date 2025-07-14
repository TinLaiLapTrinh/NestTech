from django.forms.utils import mark_safe
from django.contrib import admin
from .models import User
from admin_site.site import technest_admin_site
from unfold.admin import ModelAdmin
from admin_site.components import action_button, option_display
from utils.choice import UserType


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
        ("Location", {"fields": ["address", "district", "province"]}),
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



technest_admin_site.register(User, UserAdmin)
