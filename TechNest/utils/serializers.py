from rest_framework import serializers

class ImageSerializer(serializers.Serializer):
    """
    Serializer cho các model kế thừa từ abstract Image model
    """

    id = serializers.IntegerField(read_only=True)
    image = serializers.CharField(read_only=True)  # CloudinaryField sẽ được chuyển thành string
    alt = serializers.CharField(max_length=256, required=False, allow_null=True)

    def to_representation(self, image_object):
        """
        Ghi đè phương thức to_representation
        để thêm URL của hình ảnh vào dữ liệu trả về.
        """
        data = {
            'id': image_object.id,
            'alt': image_object.alt,
            'image': image_object.get_url() if image_object.image else None
        }
        return data
