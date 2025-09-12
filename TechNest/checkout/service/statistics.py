from django.db.models import Count, Sum, F
from datetime import date
from ..models import OrderDetail
from utils.choice import DeliveryStatus
from django.utils import timezone

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

    # Lọc theo sản phẩm thuộc về supplier
    qs = OrderDetail.objects.filter(product__product__owner=user)

    stats = {
        
        "total_orders_this_month": qs.filter(order__created_at__gte=month_start).count(),


        "delivered_today": qs.filter(
            delivery_status=DeliveryStatus.DELIVERED,
            last_update_at__gte=today_start
        ).count(),


        "not_delivered": qs.exclude(delivery_status=DeliveryStatus.DELIVERED).count(),


        "revenue": qs.filter(delivery_status=DeliveryStatus.DELIVERED).aggregate(
            total=Sum(F("quantity") * F("price"))
        )["total"] or 0,
    }
    return stats

