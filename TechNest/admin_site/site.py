from unfold.sites import UnfoldAdminSite
from django.db.models.functions import TruncMonth, TruncQuarter, TruncYear
from django.db.models import Count
from accounts.models import User
from products.models import Product, Category
from checkout.models import OrderDetail
from utils.choice import UserType


def aggregate_by_period(queryset, date_field, group_field=None, period="month"):
    # Chọn hàm Trunc tương ứng
    if period == "month":
        trunc_func = TruncMonth
        fmt = "%b %Y"
    elif period == "quarter":
        trunc_func = TruncQuarter
        fmt = "%Y-Q%q"
    elif period == "year":
        trunc_func = TruncYear
        fmt = "%Y"
    else:
        raise ValueError("Period must be 'month', 'quarter', or 'year'")

    qs = queryset.annotate(period=trunc_func(date_field))
    values_list = ["period"]
    if group_field:
        values_list.append(group_field)
    qs = qs.values(*values_list).annotate(total=Count("id")).order_by("period")

    labels = sorted({x["period"].strftime(fmt) for x in qs})
    if group_field:
        groups = set(x[group_field] for x in qs)
        data_dict = {}
        for g in groups:
            data_dict[g] = [
                next((x["total"] for x in qs if x["period"].strftime(fmt) == label and x[group_field] == g), 0)
                for label in labels
            ]
        return labels, data_dict
    else:
        data = [x["total"] for x in qs]
        return labels, data


class TechNestAdminSite(UnfoldAdminSite):
    site_header = "TechNest Admin"
    site_title = "TechNest Admin Portal"
    index_title = "Welcome to TechNest Admin Portal"

    def index(self, request, extra_context=None):
        extra_context = extra_context or {}

        # QuerySets
        users_qs = User.objects.all()
        products_qs = Product.objects.all()
        orders_qs = OrderDetail.objects.all()

        # Thống kê người dùng
        total_customers = users_qs.filter(user_type=UserType.CUSTOMER).count()
        total_suppliers = users_qs.filter(user_type=UserType.SUPPLIER).count()

        # Thống kê sản phẩm theo danh mục
        products_by_category = (
            products_qs.values("category__type")
            .annotate(total=Count("id"))
            .order_by("-total")
        )

        # Thống kê đơn hàng theo danh mục sản phẩm
        orders_by_category = (
            orders_qs.values("product__product__category__type")
            .annotate(total=Count("id"))
            .order_by("-total")
        )

        extra_context.update({
            "total_customers": total_customers,
            "total_suppliers": total_suppliers,

            # Sản phẩm
            "category_labels": [p["category__type"] or "Khác" for p in products_by_category],
            "category_product_counts": [p["total"] for p in products_by_category],

            # Đơn hàng
            "order_category_labels": [o["product__product__category__type"] or "Khác" for o in orders_by_category],
            "order_category_counts": [o["total"] for o in orders_by_category],
        })
        return super().index(request, extra_context=extra_context)


technest_admin_site = TechNestAdminSite(name="technest_admin")
