from django.db import models
from utils.models import BaseModel
from utils.choice import DeliveryMethods,DeliveryStatus, UserType
from utils.geocoding import get_coordinates

class Order(BaseModel):
    total = models.FloatField(null=False)
    address = models.CharField(max_length=50, null=False)
    receiver_phone_number = models.CharField(max_length=13,null=False)
    delivery_methods = models.CharField(max_length=10, choices=DeliveryMethods, default=DeliveryMethods.NORMAL)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    def save(self, *args, **kwargs):
        """
        Lưu toạ độ của dãy trọ dựa trên địa chỉ của nó.
        """
        # Nếu chưa có toạ độ, lấy toạ độ từ địa chỉ
        if not self.latitude or not self.longitude:
            address = f"{self.address}, {self.ward}, {self.province}, Việt Nam"
            self.latitude, self.longitude = get_coordinates(address)

        # Cập nhật toạ độ khi địa chỉ thay đổi
        if self.pk:
            old_property = Order.objects.get(pk=self.pk)
            if (
                self.address != old_property.address
                or self.province != old_property.province
                or self.ward != old_property.ward
            ):
                address = f"{self.address}, {self.ward},  {self.province}, Việt Nam"
                self.latitude, self.longitude = get_coordinates(address)

        super().save(*args, **kwargs)

class OrderDetail(BaseModel):
    product = models.ForeignKey('products.ProductVariant',related_name='order_detail',on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(null=False)
    price = models.FloatField()
    distance = models.FloatField(null=False)
    delivery_charge = models.FloatField(null=False)
    delivery_status = models.TextField(choices=DeliveryStatus, default=DeliveryStatus.PENDING)

class ShoppingCart(models.Model):
    owner = models.OneToOneField('accounts.User',related_name='shopping_cart',
                              on_delete=models.CASCADE,
                              limit_choices_to={'user_type':UserType.CUSTOMER})

class ShoppingCartItem(BaseModel):
    product = models.ForeignKey('products.ProductVariant',related_name='shopping_cart_item',on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(null=False)
    shopping_cart = models.ForeignKey('ShoppingCart',related_name='shopping_cart_item',on_delete=models.CASCADE)
    class Meta:
        unique_together = ('shopping_cart', 'product')