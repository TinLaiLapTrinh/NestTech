from unfold.sites import UnfoldAdminSite


class TechNestAdminSite(UnfoldAdminSite):
    site_header = "TechNest Admin"
    site_title = "TechNest Admin Portal"
    index_title = "Welcome to TechNest Admin Portal"

    
    # def get_urls(self):
    #     urls = super().get_urls()
    #     custom_urls = [
    #         path('renthub-stats/', self.admin_view(self.renthub_stats), name='renthub_stats'),
    #     ]
    #     return custom_urls + urls

   
technest_admin_site = TechNestAdminSite(name="renthub_admin")