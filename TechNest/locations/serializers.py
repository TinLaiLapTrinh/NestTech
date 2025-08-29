from rest_framework import serializers

from .models import  Province, Ward, UserLocation, ShippingRoute,ShippingRate

        
class ProvinceSerializer(serializers.ModelSerializer):
    """
    Serializer cho Province
    """

    class Meta:
        model = Province
        fields = '__all__'
        


        
        
class WardSerializer(serializers.ModelSerializer):
    """
    Serializer cho Ward
    """

    class Meta:
        model = Ward
        fields = ["code", "full_name"]

class UserLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserLocation
        fields = ['id','user','address','province','ward','latitude','longitude']
        read_only_fields = ['user']
    
    def to_representation(self, instance):
        data = super().to_representation(instance)
        
        data['province'] = instance.province.name if instance.province else None
        data['ward'] = instance.ward.name if instance.ward else None
        return data
    
class ShippingRateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShippingRate
        fields =["method","price"]
    
class ShippingRouteSerializer(serializers.ModelSerializer):
    shipping_rates = ShippingRateSerializer(source="rates", many=True)
    class Meta:
        model = ShippingRoute
        fields = ["origin_region", "destination_region", "shipping_rates"]