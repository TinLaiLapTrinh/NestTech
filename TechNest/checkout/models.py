from django.db import models
from utils.models import BaseModel, Image
from utils.choice import DeliveryMethods,DeliveryStatus, UserType
from utils.geocoding import get_coordinates

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





class Order(BaseModel):
    total = models.DecimalField(max_digits=12, decimal_places=2, null=True)
    owner = models.ForeignKey("accounts.User", related_name="orders",null=True,blank=True,on_delete=models.SET_NULL,limit_choices_to={'user_type':UserType.CUSTOMER})
    province = models.ForeignKey('locations.Province', null=True, on_delete=models.CASCADE)
    district = models.ForeignKey('locations.District', null=True, on_delete=models.CASCADE)
    ward = models.ForeignKey('locations.Ward',null=True,on_delete=models.CASCADE)
    address = models.CharField(max_length=100, null=False)
    receiver_phone_number = models.CharField(max_length=13,null=False)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    def save(self, *args, **kwargs):
        """
        Lưu toạ độ của dãy trọ dựa trên địa chỉ của nó.
        """
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
    order = models.ForeignKey('Order',related_name='order_details',on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(null=False)
    price = models.DecimalField(max_digits=12, decimal_places=2)
    distance = models.FloatField(null=False)
    delivery_charge = models.DecimalField(max_digits=12, decimal_places=2)
    delivery_person = models.ForeignKey('accounts.User', related_name='order_delivery', null=True,blank=True ,on_delete=models.SET_NULL,limit_choices_to={'user_type':UserType.DELIVER_PERSON})
    delivery_status = models.TextField(choices=DeliveryStatus, default=DeliveryStatus.PENDING)  
    delivery_method = models.CharField(max_length=10, choices=DeliveryMethods, default=DeliveryMethods.NORMAL)
    delivery_route = models.ForeignKey('locations.ShippingRoute', related_name='order_detail',on_delete=models.CASCADE)


class OrderDetailConfirmImage(Image):
    order = models.ForeignKey('OrderDetail', related_name='image_confirm', on_delete=models.CASCADE)