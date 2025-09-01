from rest_framework import serializers

from .models import  Province, District, Ward, UserLocation, ShippingRoute,ShippingRate

        
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
        fields = "__all__"
        
        
class WardSerializer(serializers.ModelSerializer):
    """
    Serializer cho Ward
    """

    class Meta:
        model = Ward
        fields = "__all__"

class UserLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserLocation
        fields = ['id','user','address','province','district','ward','latitude','longitude']
        read_only_fields = ['user']
    
    def to_representation(self, instance):
        data = super().to_representation(instance)
        
        data['province'] = {
            "code": instance.province.code,
            "name":instance.province.name,
            "full_name":instance.province.full_name,
            "administrative_region":instance.province.administrative_region.id
            }
        data['district']={
            "code":instance.district.code,
            "name":instance.district.name,
            "full_name":instance.district.full_name
        }

        data['ward'] ={ 
            "code": instance.ward.code,
            "name":instance.ward.name,
            "full_name":instance.ward.full_name
            }
        
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

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["origin_region"] = instance.origin_region.name  
        data["destination_region"] = instance.destination_region.name
        return data
    