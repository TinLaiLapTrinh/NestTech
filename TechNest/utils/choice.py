from django.db import models

class UserType(models.TextChoices):
    """
    Loại người dùng
    """
    SUPPLIER = "supplier", "Người bán"
    CUSTOMER = "customer", "Người mua"
    DELIVER_PERSON = "delivery_person","Người giao hàng" 

class ProductStatus(models.TextChoices):
    """
    Trạng thái sản phẩm
    """

    DEPENDING= "depending","Đang kiểm duyệt"
    REJECTED="rejected","Từ chối kiểm duyệt"
    APPROVED="approved","Đã kiểm duyệt"
    OUT_OF_STOCK="out_of_stock","Hết hàng"
    INACTIVE="inactive","Tạm thời đóng mở bán"

class DeliveryMethods(models.TextChoices):
    """
    Các dạng vận chuyển
    """
    FAST = "fast","Nhanh"
    NORMAL = "normal","Trung bình"

class DeliveryStatus(models.TextChoices):
    """
    Các trạng thái của đơn hàng khi vận chuyển
    """
    PENDING = "pending", "Chờ xử lý"

    CONFIRM = "confirm", "Đã xác nhận"

    PROCESSING = "processing", "Đang chuẩn bị hàng"

    SHIPPED = "shipped", "Đang giao hàng"

    DELIVERED = "delivered", "Đã giao"

    RETURNED_TO_SENDER = "returned_to_sender","Trả hàng"

    CANCELLED = "cancelled", "Đã hủy"

    REFUNDED = "refunded", "Đã hoàn tiền"

class PaymentStatus:
    PENDING = "pending"
    PAID = "paid"
    FAILED = "failed"
    CANCELLED = "cancelled"

    CHOICES = [
        (PENDING, "Chờ thanh toán"),
        (PAID, "Đã thanh toán"),
        (FAILED, "Thanh toán thất bại"),
        (CANCELLED, "Đã hủy"),
    ]

class PaymentMethod:
    COD = "cod"
    VNPAY = "vnpay"

    CHOICES = [
        (COD, "Thanh toán khi nhận hàng"),
        (VNPAY, "vnpay"),
    ]