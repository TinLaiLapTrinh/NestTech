from django.urls import path
from admin_site.site import technest_admin_site



urlpatterns = [
    path('', technest_admin_site.urls),  
]
