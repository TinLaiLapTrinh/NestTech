from rest_framework import generics, mixins, viewsets, status
from rest_framework.permissions import IsAuthenticated
from locations.serializers import  ProvinceSerializer, WardSerializer, UserLocationSerializer
from .models import Province, Ward, UserLocation

from rest_framework.decorators import action
from rest_framework.response import Response


class ProvinceViewSet(viewsets.GenericViewSet, mixins.ListModelMixin):
    """
    ViewSet cho `Province`:
    - Trả về danh sách các tỉnh của Việt Nam
    """

    queryset = Province.objects.all()
    serializer_class = ProvinceSerializer

    @action(detail=True, methods=['get'], url_path='wards')
    def wards(self, request, pk=None):
        wards = Ward.objects.filter(province_id=pk)
        serializer = WardSerializer(wards, many=True)
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
            {"message": "order created successfully!", "location": serializer.instance.id},
            status=status.HTTP_201_CREATED
        )


