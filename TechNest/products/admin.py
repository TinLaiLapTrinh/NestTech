from django.contrib import admin
from admin_site.site import technest_admin_site
from products.models import Category, Product, Option,OptionValue
from django.core.exceptions import ValidationError
from django.utils.html import format_html
from django.contrib import messages
from admin_site.components import option_display
from utils.choice import ProductStatus
from unfold.admin import ModelAdmin
from accounts.models import AuditLog




class CategoryAdmin(ModelAdmin):
    list_display = ['id', 'created_at', 'type', 'descriptions']
    list_filter = ['id', 'created_at']

    def delete_model(self, request, obj):
        if obj.products.exists():
            self.message_user(
                request,
                "Không thể xoá Category vì có sản phẩm liên kết.",
                level=messages.ERROR
            )
        else:
            super().delete_model(request, obj)      



class ProductApproved(ModelAdmin):
    list_display = ['name','owner','category_name','status_display']
    readonly_fields = ['image_gallery', 'owner']
    fieldsets = [
        ("Status", {"fields": ["status"]}),
        ("Detail", {"fields": ["name", "owner","category"]}),
        ("Location", {"fields": ["address", "province","district", "ward"]}),
        ("Images", {"fields": ["image_gallery"]}),
    ]
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        # Lấy danh sách user_id đã được xác minh
        verified_user_ids = AuditLog.objects.filter(verified=True).values_list('user_id', flat=True)
        # Lọc product chỉ lấy những sản phẩm mà owner đã xác minh
        return qs.filter(owner_id__in=verified_user_ids)

    # Các hàm còn lại giữ nguyên
    def category_name(self, obj):
        if obj.category is None:  
            return "Không có danh mục"
        return obj.category.type  
    category_name.short_description = "Danh mục"

    def image_gallery(self, product: Product):
        html = '<div style="display: flex; gap: 10px; flex-wrap: wrap;">'
        for image_object in product.images.all():
            html += '<div style="margin: 10px;">'
            html += image_object.get_image_element(transformations={"width": 200})
            html += f'<p style="color: grey; font-style: italic;">{image_object.image.public_id or ""}</p>'
            html += f'<p>{image_object.alt or ""}</p>'
            html += '</div>'
        html += '</div>'
        return format_html(html)
    image_gallery.short_description = 'Image Gallery'

    def status_display(self, product: Product):
        if product.status == ProductStatus.DEPENDING:
            return option_display("Pending", color="yellow")
        if product.status == ProductStatus.APPROVED:
            return option_display("Approved", color="green")
        if product.status == ProductStatus.REJECTED:
            return option_display("Rejected", color="red")
        if product.status == ProductStatus.OUT_OF_STOCK:
            return option_display("Rejected", color="blue")
        if product.status == ProductStatus.INACTIVE:
            return option_display("Rejected", color="white")
    status_display.short_description = "Status"

    def save_model(self, request, obj, form, change):
        obj.active = obj.status == ProductStatus.APPROVED
        super().save_model(request, obj, form, change)

    class Media:
        js = ("js/locations.js",)


technest_admin_site.register(Category, CategoryAdmin)
technest_admin_site.register(Product, ProductApproved)



