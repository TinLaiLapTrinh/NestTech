from django.db.models import Count, Sum, F
from datetime import date
from ..models import OrderDetail
from products.models import Rate
from utils.choice import DeliveryStatus
from django.utils import timezone
from django.db.models.functions import TruncDay



def stats_for_shipper(user):
    now = timezone.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    qs = OrderDetail.objects.filter(delivery_person=user)

    stats = {
        "delivered_today": qs.filter(delivery_status=DeliveryStatus.DELIVERED, last_update_at__gte=today_start).count(),
        "total_this_month": qs.filter(created_at__gte=month_start).count(),
        "shipped": qs.filter(delivery_status=DeliveryStatus.SHIPPED).count(),
        "cancelled": qs.filter(delivery_status=DeliveryStatus.CANCELLED).count(),
    }
    return stats

def stats_for_supplier(user):
    now = timezone.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    qs = OrderDetail.objects.filter(product__product__owner=user)

    stats = {
        "overview": {
            "orders_today": qs.filter(order__created_at__gte=today_start).count(),
            "orders_this_month": qs.filter(order__created_at__gte=month_start).count(),
            "revenue_today": qs.filter(
                delivery_status=DeliveryStatus.DELIVERED,
                last_update_at__gte=today_start
            ).aggregate(total=Sum(F("quantity") * F("price")))["total"] or 0,
            "revenue_this_month": qs.filter(
                delivery_status=DeliveryStatus.DELIVERED,
                last_update_at__gte=month_start
            ).aggregate(total=Sum(F("quantity") * F("price")))["total"] or 0,
        },
        "status_distribution": qs.values("delivery_status")
            .annotate(count=Count("id")),
        "trend": qs.filter(order__created_at__gte=month_start)
            .annotate(day=TruncDay("order__created_at"))
            .values("day")
            .annotate(
                total_orders=Count("id"),
                revenue=Sum(F("quantity") * F("price"))
            )
            .order_by("day"),
        "top_products": qs.filter(order__created_at__gte=month_start)
            .values("product__product__name")
            .annotate(
                total_qty=Sum("quantity"),
                revenue=Sum(F("quantity") * F("price"))
            )
            .order_by("-revenue")[:5],
        "top_rated": Rate.objects.filter(
        rate__gte=4,
        rate__lte=5,
        is_spam=False,
        product__owner=user
    )
    .values("product__name")
    .annotate(count=Count("id"))
    .order_by("-count")[:5],
    }
    return stats

