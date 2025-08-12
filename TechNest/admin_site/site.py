from unfold.sites import UnfoldAdminSite


class TechNestAdminSite(UnfoldAdminSite):
    site_header = "TechNest Admin"
    site_title = "TechNest Admin Portal"
    index_title = "Welcome to TechNest Admin Portal"
   
    def get_app_list(self, request, app_label=None):
        """
        Override phương thức get_app_list với đầy đủ tham số
        """
        app_list = super().get_app_list(request, app_label)
        

        
        return app_list
    


   
technest_admin_site = TechNestAdminSite(name="technest_admin")