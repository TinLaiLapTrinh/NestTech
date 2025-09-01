from rest_framework import generics, mixins, viewsets, status
from rest_framework.permissions import IsAuthenticated
from locations.serializers import  ProvinceSerializer, DistrictSerializer, WardSerializer, UserLocationSerializer, ShippingRouteSerializer
from .models import Province, District, Ward, UserLocation, ShippingRoute,ShippingRate

from rest_framework.decorators import action
from rest_framework.response import Response


class LocationViewSet(viewsets.ViewSet):
    """
    Endpoints:
    - /location/province/
    - /location/province/{province_id}/district/
    - /location/province/{province_id}/district/{district_id}/ward/
    """

    @action(detail=False, methods=["get"])
    def province(self, request):
        provinces = Province.objects.all()
        serializer = ProvinceSerializer(provinces, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=["get"], url_path="district")
    def district(self, request, pk=None):
        districts = District.objects.filter(province_id=pk)
        serializer = DistrictSerializer(districts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"], url_path="district/(?P<district_id>[^/.]+)/ward")
    def ward(self, request, district_id=None):
        wards = Ward.objects.filter(district_id=district_id)
        serializer = WardSerializer(wards, many=True)
        return Response(serializer.data)
    
class ShippingRouteViewSet(viewsets.GenericViewSet, mixins.ListModelMixin, mixins.RetrieveModelMixin):
    serializer_class = ShippingRouteSerializer
    queryset = ShippingRoute.objects.all()

    @action(detail=False, methods=["get"],url_path="find-by-regions")
    def find_by_regions(self, request):
        origin_id = request.query_params.get("origin")
        dest_id = request.query_params.get("destination")

        if not origin_id or not dest_id:
            return Response({"error": "origin và destination là bắt buộc"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            route = ShippingRoute.objects.get(origin_region_id=origin_id, destination_region_id=dest_id)
        except ShippingRoute.DoesNotExist:
            return Response({"error": "Không tìm thấy route"}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(route)
        return Response(serializer.data)
    


class UserLocationViewSet(viewsets.ModelViewSet):
    serializer_class = UserLocationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if getattr(self, 'swagger_fake_view', False):
            return UserLocation.objects.none()
        return UserLocation.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = self.perform_create(serializer)
        return Response(
            {"message": "location created successfully!", "location": serializer.instance.id},
            status=status.HTTP_201_CREATED
        )


