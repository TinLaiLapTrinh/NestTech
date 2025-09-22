from django.db import models
from cloudinary.models import CloudinaryField
from cloudinary import uploader
import cloudinary
from django.utils.safestring import mark_safe



class BaseModel(models.Model):
    active = models.BooleanField(default=True)
    created_at= models.DateTimeField(auto_now_add=True)
    last_update_at=models.DateTimeField(auto_now=True, null=True)

    class Meta:
        abstract = True

class Image(models.Model):
    
    image = CloudinaryField(null=False)
    alt = models.CharField(max_length=256, blank=True, null=True)

    class Meta:
        abstract = True

    def __str__(self):
        return f"{self.image.public_id}"

    def delete(self, *args, **kwargs):
        """
        Xóa ảnh trên Cloudinary trước khi xóa record
        """
        if self.image.public_id:
            uploader.destroy(self.image.public_id)
        super().delete(*args, **kwargs)

    def get_url(self, transformations=""):
        '''
        Tạo URL cho ảnh cloudinary
        :param transformations: Các biến đổi ảnh
        :return: URL ảnh
        '''
        url = cloudinary.utils.cloudinary_url(
            self.image.public_id,
            cloud_name=cloudinary.config().cloud_name, 
            secure=True,  # Đảm bảo HTTPS
            transformation=transformations
        )[0]
        return url

    def get_image_element(self, transformations=""):
        '''
        Hiển thị ảnh từ cloudinary
        :param transformations: Các biến đổi ảnh
        :return: Ảnh
        '''
        image_url = self.get_url(transformations)

        return mark_safe(f"<img src='{image_url}' />")