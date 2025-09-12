import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/features/checkout/services/checkout_service.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

class DeliveryDetailScreen extends StatefulWidget {
  final int orderId;
  const DeliveryDetailScreen({super.key, required this.orderId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  mb.MapboxMap? mapboxMap;
  mb.PolylineAnnotationManager? polylineManager;
  Map<String, dynamic>? orderDetail;
  bool showMap = false;
  geo.Position? userPosition;

  mb.Position? startPoint;
  mb.Position? endPoint;

  final String accessToken =
      "pk.eyJ1IjoidHJvbmd0aW4xMjkyMDA0IiwiYSI6ImNtZXZsMnhnbzBlbmUyaW9kcjhsb2k2cXAifQ.EmlCJ9BsD-p2C5nr_dlOYA";

  @override
  void initState() {
    super.initState();
    _loadRetrieveOrder();
    _getUserLocation();
    mb.MapboxOptions.setAccessToken(accessToken);
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("GPS chưa bật");

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối');
        }
      }
      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Quyền truy cập vị trí bị chặn vĩnh viễn');
      }

      userPosition = await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );
      setState(() {});
    } catch (e) {
      print("Lỗi lấy vị trí người dùng: $e");
    }
  }

  Future<List<mb.Position>> getRouteFromMapbox(mb.Position start, mb.Position end) async {
    final url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/${start.lng},${start.lat};${end.lng},${end.lat}?geometries=geojson&overview=full&access_token=$accessToken";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      return coords.map((c) => mb.Position(c[0], c[1])).toList();
    } else {
      throw Exception("Failed to load route: ${response.statusCode}");
    }
  }

  Future<void> _loadRetrieveOrder() async {
    try {
      final res = await CheckoutService.orderDetailRetrieve(widget.orderId);
      setState(() {
        orderDetail = res;
      });
    } catch (e) {
      print("Error fetching order: $e");
    }
  }

  void _onMapCreated(mb.MapboxMap map) async {
    if (userPosition == null || orderDetail == null) return;

    mapboxMap = map;

    final pointManager = await map.annotations.createPointAnnotationManager();
    polylineManager = await map.annotations.createPolylineAnnotationManager();

    // Vị trí shipper
    final startLat = userPosition!.latitude;
    final startLng = userPosition!.longitude;
    startPoint = mb.Position(startLng, startLat);

    // Vị trí khách hàng
    final routeInfo = orderDetail!['route_info'];
    final customerLat = routeInfo?['to']?['latitude'];
    final customerLng = routeInfo?['to']?['longitude'];
    if (customerLat == null || customerLng == null) return;
    endPoint = mb.Position(customerLng, customerLat);

    // Marker shipper
    await pointManager.create(
      mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: startPoint!),
        iconImage: "shipper-icon",
        iconSize: 1.5,
        textField: "Shipper",
        textColor: 0xFF00FF00,
        textSize: 14,
      ),
    );

    // Marker khách hàng
    await pointManager.create(
      mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: endPoint!),
        iconImage: "customer-icon",
        iconSize: 1.5,
        textField: "Khách hàng",
        textColor: 0xFF007AFF,
        textSize: 14,
      ),
    );

    // Lấy route
    List<mb.Position> route = [];
    try {
      route = await getRouteFromMapbox(startPoint!, endPoint!);
    } catch (e) {
      route = [
        startPoint!,
        mb.Position(
          (startPoint!.lat + endPoint!.lat) / 2,
          (startPoint!.lng + endPoint!.lng) / 2,
        ),
        endPoint!,
      ];
    }

    // Vẽ polyline
    if (route.isNotEmpty) {
      await polylineManager!.create(
        mb.PolylineAnnotationOptions(
          geometry: mb.LineString(coordinates: route),
          lineColor: 0xFF1E90FF,
          lineWidth: 5,
        ),
      );
    }

    // Fit camera
    final coordinates = [
      mb.Point(coordinates: startPoint!),
      mb.Point(coordinates: endPoint!),
    ];
    final cameraOptions = await map.cameraForCoordinates(
      coordinates,
      mb.MbxEdgeInsets(top: 100, left: 100, bottom: 100, right: 100),
      null,
      null,
    );
    await map.setCamera(cameraOptions);
  }

  Future<Offset?> _getPixelForCoordinate(mb.Position? pos) async {
    if (pos == null || mapboxMap == null) return null;
    final point = await mapboxMap!.pixelForCoordinate(mb.Point(coordinates: pos));
    return Offset(point.x, point.y);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết đơn hàng")),
      body: orderDetail == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sản phẩm: ${orderDetail!['product']['product']['name']}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("Số lượng: ${orderDetail!['quantity']}"),
                  Text("Giá: ${orderDetail!['price']}"),
                  Text("Tình trạng giao hàng: ${orderDetail!['delivery_status']}"),
                  Text("Khách hàng: ${orderDetail!['recieve_info']['customer']}"),
                  Text("Số điện thoại: ${orderDetail!['recieve_info']['phone']}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (userPosition == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Đang lấy vị trí hiện tại, vui lòng thử lại"),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        showMap = true;
                      });
                    },
                    child: const Text("Xem bản đồ giao hàng"),
                  ),
                  const SizedBox(height: 16),
                  if (showMap)
                    SizedBox(
                      height: 400,
                      child: mb.MapWidget(
                        styleUri: "mapbox://styles/mapbox/streets-v11",
                        onMapCreated: _onMapCreated,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
