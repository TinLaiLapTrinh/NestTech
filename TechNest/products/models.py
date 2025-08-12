from django.db import models
from utils.models import BaseModel, Image
from utils.choice import UserType, ProductStatus

class Category(BaseModel):
    type = models.CharField(max_length=50, unique=True)
    descriptions = models.TextField(null=True)
    class Meta:
        verbose_name = "Category"
        verbose_name_plural = "Categories" 

    def __str__(self):
        return self.type 


class Option(models.Model):
    type=models.CharField(max_length=30, null=True)
    category = models.ForeignKey('Category', null=True, blank=True,related_name='options',on_delete=models.PROTECT)

    class Meta:
        unique_together = ('type', 'category') 

class OptionValue(models.Model):
    value = models.CharField(max_length=30)
    option = models.ForeignKey('Option', related_name='option_values',  on_delete=models.PROTECT)
    class Meta:
        unique_together = ('value', 'option') 

class Product(BaseModel):
    name = models.CharField(max_length=50,null=False)
    status = models.CharField(max_length=20, choices=ProductStatus,default=ProductStatus.DEPENDING)
    max_price = models.FloatField(null=True)
    min_price = models.FloatField(null=True)
    owner = models.ForeignKey('accounts.User', related_name='products',on_delete=models.CASCADE, limit_choices_to={'user_type':UserType.SUPPLIER})
    description = models.TextField(null=True)
    rate_avg=models.FloatField(default=0.0)
    category = models.ForeignKey('Category',related_name="products",on_delete=models.PROTECT, null=True)
    sold_quantity = models.PositiveIntegerField(default=0)

    province = models.ForeignKey(
        "locations.Province",
        on_delete=models.SET_NULL,
        related_name='products',
        null=True
    )
    ward = models.ForeignKey(
        "locations.Ward",
        on_delete=models.SET_NULL,
        related_name='products',
        null=True
    )
    address = models.CharField(max_length=256, null=True)
    is_deleted = models.BooleanField(default=False)



class ProductVariant(BaseModel):
    price = models.FloatField(default=0.0)
    product = models.ForeignKey('Product',related_name='product_variant', on_delete=models.PROTECT)
    stock = models.PositiveIntegerField(default=0)
    sku = models.CharField(max_length=20, null=True, unique=True)
# todo: thêm giá của mỗi value khi người dùng truyền vào
class VariantOptionValue(models.Model):
    option_value=models.ForeignKey('OptionValue',on_delete=models.CASCADE)
    product_variant  = models.ForeignKey('ProductVariant',on_delete=models.CASCADE)
    class Meta:
        unique_together = ('option_value', 'product_variant') 
        indexes = [
            models.Index(fields=['option_value', 'product_variant'])
        ]


class Comment(BaseModel):
    product = models.ForeignKey('Product',related_name='comments',on_delete=models.CASCADE)
    content = models.TextField(null=False)
    is_spam = models.BooleanField(default=False)
    owner = models.ForeignKey('accounts.User', related_name='comments', on_delete=models.SET_NULL, null=True)

class Rate(BaseModel):
    product = models.ForeignKey('Product',related_name='rates',on_delete=models.CASCADE)
    order_detail = models.ForeignKey('checkout.OrderDetail', related_name='rate',on_delete=models.SET_NULL, null=True)
    rate = models.FloatField(default=0.0,null=False)
    content = models.TextField(null=True)
    ip_address = models.GenericIPAddressField(null=True)
    is_spam = models.BooleanField(default=False)
    owner = models.ForeignKey('accounts.User',related_name='rates',on_delete=models.SET_NULL,limit_choices_to={'user_type':UserType.CUSTOMER}, null=True)
    
class ProductImage(Image):
    product = models.ForeignKey('Product',related_name='images', on_delete=models.CASCADE)
    
class RateImage(Image):
    rate = models.ForeignKey('Rate', related_name='images',on_delete=models.CASCADE)

class Cart(BaseModel):
    owner = models.OneToOneField('accounts.User', related_name='cart', on_delete=models.CASCADE)

class ProductCartItem(BaseModel):
    cart = models.ForeignKey('Cart', related_name='product_cart', on_delete=models.CASCADE)
    product_variant = models.ForeignKey('ProductVariant',related_name='product_cart',on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)








