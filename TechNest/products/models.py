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




class Product(BaseModel):
    name = models.CharField(max_length=100,null=False)
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

    def save(self, *args, **kwargs):
        is_new = self.pk is None
        super().save(*args, **kwargs)
        # Nếu là product mới và có min_price thì tạo variant ngay
        if is_new and self.min_price is not None:
            ProductVariant.objects.create(
                product=self,
                price=self.min_price,
                stock=0,  # stock mặc định
                sku=f"{self.id}-{int(self.min_price)}"  # tạo SKU tự động
            )


# thêm 1 trường yêu cầu hình ảnh vào đây để khi người dùng ấn là có thì sẽ hiển thị ô thêm ảnh
class Option(models.Model):
    type=models.CharField(max_length=30, null=True)
    product = models.ForeignKey('Product', null=True, blank=True,related_name='product_options',on_delete=models.CASCADE)
    image_require = models.BooleanField(default=False)

    class Meta:
        unique_together = ('type', 'product') 

    def __str__(self):
        return self.type 
class OptionValue(models.Model):
    value = models.CharField(max_length=30)
    option = models.ForeignKey('Option', related_name='option_values',  on_delete=models.PROTECT)
    class Meta:
        unique_together = ('value', 'option') 

class OptionValueImage(Image):
    option_value = models.OneToOneField('OptionValue',related_name='images', on_delete=models.CASCADE)
    

class ProductVariant(BaseModel):
    price = models.FloatField(default=0.0)
    product = models.ForeignKey('Product',related_name='product_variant', on_delete=models.PROTECT)
    stock = models.PositiveIntegerField(default=0)
    sku = models.CharField(max_length=20, null=True, unique=True)
    
class VariantOptionValue(models.Model):
    option_value=models.ForeignKey('OptionValue',related_name="variant_option_values",on_delete=models.CASCADE)
    product_variant  = models.ForeignKey('ProductVariant',related_name="variant_option_values",on_delete=models.CASCADE)
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










