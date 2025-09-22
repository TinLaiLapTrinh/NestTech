from rest_framework.pagination import PageNumberPagination


class ShoppingCartItemPaginator(PageNumberPagination):
    page_size = 10

class OrderDetailItemPaginator(PageNumberPagination):
    page_size = 10
