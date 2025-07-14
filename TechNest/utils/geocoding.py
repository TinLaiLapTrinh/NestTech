from math import atan2, cos, radians, sin, sqrt
import requests
from django.conf import settings


def get_coordinates(address) -> tuple:
    """
    Sử dụng Google Geocoding API để lấy tọa độ từ địa chỉ.

    Returns
    -------
    - Một tuple chứa vĩ độ và kinh độ (latitude, longitude)
    """
    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {"address": address, "key": settings.GOOGLE_MAPS_API_KEY}
    response = requests.get(url, params=params)
    if response.status_code == 200:
        data = response.json()
        if data["results"]:
            location = data["results"][0]["geometry"]["location"]
            return location["lat"], location["lng"]
    return None, None


def get_bounding_box(lat, lon, radius_km=5):
    """
    Tính toán `bounding_box` (là một hình chữ nhật) để giới hạn phạm vi lọc.

    Parameters
    ----------
    - `lat` và `lon` - Toạ độ tâm của hình chữ nhật
    - `radius_km` - Chiều dài/rộng của hình chữ nhật

    Returns
    -------
    Một dict chứa toạ độ của hình chữ nhật
    - `min_lat` - Vĩ độ nhỏ nhất (cạnh phía nam)
    - `max_lat` - Vĩ độ lớn nhất (cạnh phía bắc)
    - `min_lon` - Kinh độ nhỏ nhất (cạnh phía tây)
    - `max_lon` - Kinh độ lớn nhất (cạnh phía đông)
    """
    lat_delta = radius_km / 111.0
    lon_delta = radius_km / (111.0 * cos(radians(lat)))

    return {
        "min_lat": lat - lat_delta,
        "max_lat": lat + lat_delta,
        "min_lon": lon - lon_delta,
        "max_lon": lon + lon_delta,
    }


def haversine(lat1, lon1, lat2, lon2):
    """
    Tính khoảng cách chính xác giữa hai điểm trên trái đất theo km, dựa vào
    phương trình Haversine

    Vì sao lại không dùng Euclidean?
    -> Vì trái đất là hình cầu, nên phương trình Euclidean không chính xác được

    Paramenters
    -----------
    - `lat1` và `lon1` - Toạ độ vị trí thứ nhất
    - `lat2` và `lon2` - Toạ độ vị trí thứ hai

    Returns
    -------
    Trả về khoảng cách giữa hai vị trí trên trái đất theo km
    """
    R = 6371  # Bán kính của trái đất
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)

    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return R * c  # Kết quả tính bằng kilomet
