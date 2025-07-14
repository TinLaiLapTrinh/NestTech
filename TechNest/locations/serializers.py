from rest_framework import serializers

from .models import District, Province, Ward

        
class ProvinceSerializer(serializers.ModelSerializer):
    """
    Serializer cho Province
    """

    class Meta:
        model = Province
        fields = '__all__'
        

class DistrictSerializer(serializers.ModelSerializer):
    """
    Serializer cho District
    """

    class Meta:
        model = District
        fields = ["code", "full_name"]
        
        
class WardSerializer(serializers.ModelSerializer):
    """
    Serializer cho Ward
    """

    class Meta:
        model = Ward
        fields = ["code", "full_name"]