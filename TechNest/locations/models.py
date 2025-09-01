from django.db import models
from utils.choice import DeliveryMethods

class AdministrativeRegion(models.Model):
    id = models.AutoField(primary_key=True)  # integer NOT NULL primary key
    name = models.CharField(max_length=255)
    name_en = models.CharField(max_length=255)
    code_name = models.CharField(max_length=255, null=True, blank=True)
    code_name_en = models.CharField(max_length=255, null=True, blank=True)

    def __str__(self):
        return self.name


class AdministrativeUnit(models.Model):
    id = models.AutoField(primary_key=True)  
    full_name = models.CharField(max_length=255, null=True, blank=True)
    full_name_en = models.CharField(max_length=255, null=True, blank=True)
    short_name = models.CharField(max_length=255, null=True, blank=True)
    short_name_en = models.CharField(max_length=255, null=True, blank=True)
    code_name = models.CharField(max_length=255, null=True, blank=True)
    code_name_en = models.CharField(max_length=255, null=True, blank=True)

    def __str__(self):
        return self.full_name or self.short_name or str(self.id)


class Province(models.Model):
    code = models.CharField(max_length=20, primary_key=True)  # varchar(20) NOT NULL primary key
    name = models.CharField(max_length=255)
    name_en = models.CharField(max_length=255, null=True, blank=True)
    full_name = models.CharField(max_length=255)
    full_name_en = models.CharField(max_length=255, null=True, blank=True)
    code_name = models.CharField(max_length=255, null=True, blank=True)
    administrative_unit = models.ForeignKey(
        AdministrativeUnit,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='provinces'
    )

    administrative_region = models.ForeignKey(
        AdministrativeRegion, on_delete=models.SET_NULL, null=True, blank=True, related_name="provinces"
    )

    def __str__(self):
        return self.full_name
    
class District(models.Model):
    code = models.CharField(max_length=20, primary_key=True)
    name = models.CharField(max_length=255)
    name_en = models.CharField(max_length=255, null=True, blank=True)
    full_name = models.CharField(max_length=255, null=True, blank=True)
    full_name_en = models.CharField(max_length=255, null=True, blank=True)
    code_name = models.CharField(max_length=255, null=True, blank=True)
    province = models.ForeignKey(
        Province, on_delete=models.CASCADE, null=True, blank=True, related_name="districts"
    )
    administrative_unit = models.ForeignKey(
        AdministrativeUnit, on_delete=models.SET_NULL, null=True, blank=True, related_name="districts"
    )

    def __str__(self):
        return self.full_name


class Ward(models.Model):
    code = models.CharField(max_length=20, primary_key=True)
    name = models.CharField(max_length=255)
    name_en = models.CharField(max_length=255, null=True, blank=True)
    full_name = models.CharField(max_length=255, null=True, blank=True)
    full_name_en = models.CharField(max_length=255, null=True, blank=True)
    code_name = models.CharField(max_length=255, null=True, blank=True)
    district = models.ForeignKey(
        District,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='wards'  # ward sẽ thuộc về district
    )
    administrative_unit = models.ForeignKey(
        AdministrativeUnit,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='wards'
    )

    def __str__(self):
        return self.full_name
    

class ShippingRoute(models.Model):
    origin_region = models.ForeignKey("AdministrativeRegion", related_name="origin_rates", on_delete=models.CASCADE)
    destination_region = models.ForeignKey("AdministrativeRegion", related_name="destination_rates", on_delete=models.CASCADE)
    class Meta:
        unique_together = ("origin_region", "destination_region")

    def __str__(self):
       return f"{self.origin_region} đến {self.destination_region}"

class ShippingRate(models.Model):
    shipping_route = models.ForeignKey(
        'ShippingRoute',
        related_name='rates',
        on_delete=models.CASCADE
    )
    method = models.CharField(max_length=20, choices=DeliveryMethods)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    


class UserLocation(models.Model):
    user = models.ForeignKey('accounts.User', related_name='user_locations', on_delete=models.CASCADE)
    address = models.CharField(max_length=100,null=False)
    province=models.ForeignKey('Province', related_name='user_location',on_delete=models.CASCADE)
    district=models.ForeignKey('District', related_name='user_location',on_delete=models.CASCADE)
    ward = models.ForeignKey('Ward', related_name='user_location', on_delete=models.CASCADE)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)    