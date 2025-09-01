from django.db import models
from django.contrib.auth.models import AbstractUser
from cloudinary.models import CloudinaryField
from utils import  choice
from utils.models import BaseModel
from TechNest import settings



class User(AbstractUser):
    user_type = models.CharField(
        max_length=20,
        choices=choice.UserType,
        default=choice.UserType.CUSTOMER,
        null=False
    )
    address = models.CharField(max_length=256, blank=True, null=True)
    province = models.ForeignKey('locations.Province',on_delete=models.SET_NULL, blank=True, null=True)
    date_joined=models.DateField(auto_now_add=True,null=True)
    dob = models.DateField(blank=True, null=True)
    email = models.EmailField(blank=False, null=False, unique=True)
    avatar = CloudinaryField(null=True, blank=True)
    phone_number = models.CharField(max_length=10, unique=True, blank=True, null=True)

    class Meta:
        db_table = "user"

class SupplierApproved(User):

    class Meta:
        proxy = True

class Follow(BaseModel):
    follower = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="following", 
                                 on_delete=models.CASCADE, 
                                 limit_choices_to={"user_type": choice.UserType.CUSTOMER})
    followee = models.ForeignKey(settings.AUTH_USER_MODEL,
                                 related_name="followers",
                                 on_delete=models.CASCADE,
                                 limit_choices_to={"user_type":choice.UserType.SUPPLIER})
    
    class Meta:
        unique_together = ('follower', 'followee')

        