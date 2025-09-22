import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:url_launcher/url_launcher.dart';

// NOTE: Thêm dependency trong pubspec.yaml:
// geolocator: ^9.x
// url_launcher: ^6.x
// mapbox_maps_flutter: ... (bản bạn đang dùng)

class DeliveryDetailScreen extends StatefulWidget {
  final int orderId;
  const DeliveryDetailScreen({super.key, required this.orderId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  mb.MapboxMap? mapboxMap;
  mb.PolylineAnnotationManager? polylineManager;
  mb.PointAnnotationManager? pointManager;

  geo.Position? userPosition;
  mb.Position? startPoint;
  mb.Position? endPoint;
  double currentSpeed = 0.0; // km/h

  StreamSubscription<geo.Position>? positionStream;

  Map<String, dynamic>? orderDetail;
  bool showMap = false;

  // Route info
  List<mb.Position> routeCoordinates = [];
  double? routeDistanceMeters;
  double? routeDurationSeconds;

  // để tránh gọi route quá thường xuyên
  mb.Position? lastRouteUpdatePos;

  final String accessToken =
      "pk.eyJ1IjoidHJvbmd0aW4xMjkyMDA0IiwiYSI6ImNtZXZsMnhnbzBlbmUyaW9kcjhsb2k2cXAifQ.EmlCJ9BsD-p2C5nr_dlOYA";

  @override
  void initState() {
    super.initState();
    mb.MapboxOptions.setAccessToken(accessToken);
    _loadRetrieveOrder();
    _getUserLocation();
    _startTracking();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadRetrieveOrder() async {
    try {
      // TODO: replace with your real API call
      // final res = await CheckoutService.orderDetailRetrieve(widget.orderId);
      // setState(() { orderDetail = res; });
      // for demo, fake order:
      setState(() {
        orderDetail = {
          "product": {"name": "Điện thoại iPhone 15", "price": 28990000},
          "route_info": {
            "to": {"latitude": 21.028511, "longitude": 105.804817},
          },
          "recieve_info": {
            "customer": "Nguyễn Văn A",
            "phone": "0912345678",
            "address": "Số 1 Đường ABC, Quận XYZ",
          },
          "quantity": 1,
          "price": 28990000,
          "delivery_status": "Đang giao",
        };
      });
    } catch (e) {
      debugPrint("Error fetching order: $e");
    } finally {
      _maybeShowMap();
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // bạn có thể show dialog yêu cầu bật GPS
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) return;

      userPosition = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      _updateStartEndPoint();
      _maybeShowMap();
    } catch (e) {
      debugPrint("Lỗi lấy vị trí người dùng: $e");
    }
  }

  void _maybeShowMap() {
    if (!mounted) return;
    if (userPosition != null && orderDetail != null) {
      // thiết lập endPoint
      final customerLat = orderDetail!['route_info']?['to']?['latitude'];
      final customerLng = orderDetail!['route_info']?['to']?['longitude'];
      if (customerLat != null && customerLng != null) {
        endPoint = mb.Position(customerLng, customerLat);
      }
      setState(() {
        showMap = true;
      });
    }
  }

  void _updateStartEndPoint() {
    if (userPosition == null) return;
    startPoint = mb.Position(userPosition!.longitude, userPosition!.latitude);
  }

  Future<Map<String, dynamic>> _fetchRouteFromMapbox(
    mb.Position start,
    mb.Position end,
  ) async {
    final url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/${start.lng},${start.lat};${end.lng},${end.lat}?geometries=geojson&overview=full&access_token=$accessToken";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = (data['routes'][0]['geometry']['coordinates'] as List)
          .map((c) => mb.Position(c[0], c[1]))
          .toList();
      final distance = (data['routes'][0]['distance'] as num)
          .toDouble(); // meters
      final duration = (data['routes'][0]['duration'] as num)
          .toDouble(); // seconds
      return {'coords': coords, 'distance': distance, 'duration': duration};
    } else {
      throw Exception("Failed to load route: ${response.statusCode}");
    }
  }

  void _onMapCreated(mb.MapboxMap map) async {
    if (userPosition == null || orderDetail == null) return;

    mapboxMap = map;
    pointManager = await map.annotations.createPointAnnotationManager();
    polylineManager = await map.annotations.createPolylineAnnotationManager();

    // cập nhật điểm
    _updateStartEndPoint();

    // tạo marker khách hàng
    if (endPoint != null) {
      await pointManager!.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: endPoint!),
          iconImage: "customer-icon",
          iconSize: 1.5,
          textField: "Khách hàng",
          textColor: 0xFF007AFF,
          textSize: 14,
        ),
      );
    }

    // tạo marker shipper ban đầu
    if (startPoint != null) {
      await pointManager!.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: startPoint!),
          iconImage: "shipper-icon",
          iconSize: 1.5,
          textField: "Shipper",
          textColor: 0xFF00FF00,
          textSize: 12,
        ),
      );
    }

    // Lấy route 1 lần ban đầu (và tính distance/ETA)
    if (startPoint != null && endPoint != null) {
      try {
        final routeData = await _fetchRouteFromMapbox(startPoint!, endPoint!);
        routeCoordinates = List<mb.Position>.from(routeData['coords'] as List);
        routeDistanceMeters = routeData['distance'] as double;
        routeDurationSeconds = routeData['duration'] as double;

        await polylineManager!.create(
          mb.PolylineAnnotationOptions(
            geometry: mb.LineString(coordinates: routeCoordinates),
            lineColor: 0xFF1E90FF,
            lineWidth: 5,
          ),
        );

        // Fit camera
        final coordinates = [
          mb.Point(coordinates: startPoint!),
          mb.Point(coordinates: endPoint!),
        ];
        final cameraOptions = await map.cameraForCoordinates(
          coordinates,
          mb.MbxEdgeInsets(top: 80, left: 40, bottom: 160, right: 40),
          null,
          null,
        );
        await map.setCamera(cameraOptions);

        // lưu vị trí cập nhật route lần cuối
        lastRouteUpdatePos = startPoint;
        setState(() {});
      } catch (e) {
        debugPrint("Route error: $e");
      }
    }
  }

  void _startTracking() async {
    // kiểm permissions
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return;
    }
    if (permission == geo.LocationPermission.deniedForever) return;

    // lấy vị trí ban đầu (nếu chưa có)
    if (userPosition == null) {
      try {
        userPosition = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
          ),
        );
        _updateStartEndPoint();
        _maybeShowMap();
      } catch (e) {
        debugPrint("Initial position error: $e");
      }
    }

    // lắng nghe vị trí liên tục
    positionStream =
        geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          ),
        ).listen((geo.Position pos) async {
          userPosition = pos;
          currentSpeed = (pos.speed.isFinite ? pos.speed : 0) * 3.6;
          startPoint = mb.Position(pos.longitude, pos.latitude);

          // cập nhật UI
          setState(() {});

          // cập nhật marker shipper
          if (pointManager != null && startPoint != null) {
            await pointManager!.deleteAll();
            // recreate customer marker (nếu muốn giữ)
            if (endPoint != null) {
              await pointManager!.create(
                mb.PointAnnotationOptions(
                  geometry: mb.Point(coordinates: endPoint!),
                  iconImage: "customer-icon",
                  iconSize: 1.5,
                  textField: "Khách hàng",
                  textColor: 0xFF007AFF,
                  textSize: 14,
                ),
              );
            }

            await pointManager!.create(
              mb.PointAnnotationOptions(
                geometry: mb.Point(coordinates: startPoint!),
                iconImage: "shipper-icon",
                iconSize: 1.5,
                textField: "${currentSpeed.toStringAsFixed(1)} km/h",
                textSize: 12,
              ),
            );
          }

          // Cập nhật route nếu shipper di chuyển > 15m so với lastRouteUpdatePos
          if (startPoint != null &&
              endPoint != null &&
              polylineManager != null) {
            bool shouldUpdateRoute = false;
            if (lastRouteUpdatePos == null) {
              shouldUpdateRoute = true;
            } else {
              final movedMeters = geo.Geolocator.distanceBetween(
                lastRouteUpdatePos!.lat.toDouble(),
                lastRouteUpdatePos!.lng.toDouble(),
                startPoint!.lat.toDouble(),
                startPoint!.lng.toDouble(),
              );
              if (movedMeters > 15) shouldUpdateRoute = true;
            }

            if (shouldUpdateRoute) {
              try {
                final routeData = await _fetchRouteFromMapbox(
                  startPoint!,
                  endPoint!,
                );
                routeCoordinates = List<mb.Position>.from(
                  routeData['coords'] as List,
                );
                routeDistanceMeters = routeData['distance'] as double;
                routeDurationSeconds = routeData['duration'] as double;

                await polylineManager!.deleteAll();
                await polylineManager!.create(
                  mb.PolylineAnnotationOptions(
                    geometry: mb.LineString(coordinates: routeCoordinates),
                    lineColor: 0xFF1E90FF,
                    lineWidth: 5,
                  ),
                );

                lastRouteUpdatePos = startPoint;
                setState(() {});
              } catch (e) {
                debugPrint("Update route error: $e");
              }
            }
          }
        });
  }

  String _formatDistance(double? meters) {
    if (meters == null) return "-";
    if (meters >= 1000) return "${(meters / 1000).toStringAsFixed(2)} km";
    return "${meters.toStringAsFixed(0)} m";
  }

  String _formatDuration(double? seconds) {
    if (seconds == null) return "-";
    final int mins = (seconds / 60).round();
    if (mins < 60) return "$mins phút";
    final hours = mins ~/ 60;
    final rem = mins % 60;
    return "$hours h ${rem} phút";
  }

  Future<void> _openInGoogleMaps() async {
    if (endPoint == null) return;
    final origin = userPosition != null
        ? "${userPosition!.latitude},${userPosition!.longitude}"
        : "";
    final destination = "${endPoint!.lat},${endPoint!.lng}";
    final url = origin.isNotEmpty
        ? "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving"
        : "https://www.google.com/maps/search/?api=1&query=$destination";

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Không thể mở Google Maps")));
    }
  }

  Future<void> _centerCamera() async {
    if (mapboxMap == null || startPoint == null || endPoint == null) return;
    final cameraOptions = await mapboxMap!.cameraForCoordinates(
      [mb.Point(coordinates: startPoint!), mb.Point(coordinates: endPoint!)],
      mb.MbxEdgeInsets(top: 80, left: 40, bottom: 160, right: 40),
      null,
      null,
    );
    await mapboxMap!.setCamera(cameraOptions);
  }

  @override
  Widget build(BuildContext context) {
    final product = orderDetail?['product'];
    final receive = orderDetail?['recieve_info'];
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết đơn hàng")),
      body: orderDetail == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map area (40% height)
                if (showMap)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: mb.MapWidget(
                      styleUri: "mapbox://styles/mapbox/streets-v11",
                      onMapCreated: _onMapCreated,
                    ),
                  )
                else
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(child: Text("Đang chuẩn bị bản đồ...")),
                  ),

                // Info area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // speed / route summary
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Vận tốc: ${currentSpeed.toStringAsFixed(1)} km/h",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Khoảng cách: ${_formatDistance(routeDistanceMeters)}",
                                ),
                                Text(
                                  "ETA: ${_formatDuration(routeDurationSeconds)}",
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _openInGoogleMaps,
                                  icon: const Icon(Icons.map),
                                  label: const Text("Mở Google Maps"),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _centerCamera,
                                  icon: const Icon(Icons.my_location),
                                  label: const Text("Trung tâm"),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // product info
                        if (product != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sản phẩm: ${product['name']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Số lượng: ${orderDetail?['quantity'] ?? 1}",
                                  ),
                                  const SizedBox(height: 6),
                                  Text("Giá: ${product['price']} VND"),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // customer info
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Người nhận: ${receive?['customer'] ?? '-'}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text("SĐT: ${receive?['phone'] ?? '-'}"),
                                const SizedBox(height: 6),
                                Text("Địa chỉ: ${receive?['address'] ?? '-'}"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
