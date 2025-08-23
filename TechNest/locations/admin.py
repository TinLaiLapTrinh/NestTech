from unfold import admin 
from utils.choice import DeliveryMethods
from admin_site.components import option_display
from .models import ShippingRoute, ShippingRate
from admin_site.site import technest_admin_site




class ShippingRateInline(admin.TabularInline):
    model = ShippingRate
    extra = 0
    fields = ["method", "price"]
    show_change_link = False

    

class DeliveryRegions(admin.ModelAdmin):
    list_display = ["id", "origin_region", "destination_region"]
    list_filter = ["origin_region"]
    inlines = [ShippingRateInline]



technest_admin_site.register(ShippingRoute, DeliveryRegions)
