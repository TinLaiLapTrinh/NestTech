from django.db import models

class UserType(models.TextChoices):
    """
    Loại người dùng
    """
    SUPPLIER = "supplier", "Người bán"
    CUSTOMER = "customer", "Người mua"
    DELIVER_MAN = "delivery man","Người giao hàng" 

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
    PENDING = "pending","Chờ giao hàng"
    CONFIRM = "confirm","Đã xác nhận"
    PROCESSING = "processing","Đang xử lý"
    PACKED = "packed","Đã đóng gói"
    SHIPPED ="shipped","Đang giao hàng"
    IN_TRANSIT ="in_transit","Đang trên đường vận chuyển"
    OUT_OF_DELIVERY ="out_of_delivery","Ra khỏi kho"
    DELIVERED ="delivered","Đã giao hàng"
    FAILDED_DELIVERY_ATTEMPT = "failded_delivery_attempt","Giao hàng thất bại"
    RETURNED_TO_SENDER = "returned_to_sender","Trả hàng"
    CANCELLED = "cancelled", "Đã hủy"
    REFUNDED = "refunded", "Đã hoàn tiền"

    