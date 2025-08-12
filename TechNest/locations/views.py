from rest_framework import generics, mixins, viewsets

from locations.serializers import  ProvinceSerializer, WardSerializer

from .models import Province, Ward

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




