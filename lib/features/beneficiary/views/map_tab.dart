// lib/features/beneficiary/views/map_tab.dart
import 'dart:async';

import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Package đi kèm với flutter_map để xử lý tọa độ
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buaanyeuthuong/features/restaurants/views/restaurant_detail_screen.dart';

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  StreamSubscription? _restaurantSubscription;
  List<RestaurantModel> _restaurants = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  RestaurantModel? _selectedRestaurant;

  @override
  void initState() {
    super.initState();
    _listenToRestaurantChanges();
  }

  @override
  void dispose() {
    _restaurantSubscription?.cancel();
    super.dispose();
  }

  // Lắng nghe Stream
  void _listenToRestaurantChanges() {
    setState(() {
      _isLoading = true;
    });
    final repo = context.read<RestaurantRepository>();
    _restaurantSubscription = repo.getAllActiveRestaurantsStream().listen((
      restaurants,
    ) {
      _updateMarkers(restaurants);
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _isLoading = false;
        });
      }
    });
  }

  void _updateMarkers(List<RestaurantModel> restaurants) {
    final Set<Marker> loadedMarkers = {};
    for (final restaurant in restaurants) {
      final isSelected = _selectedRestaurant?.id == restaurant.id;
      loadedMarkers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(
            restaurant.location.latitude,
            restaurant.location.longitude,
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedRestaurant = restaurant;
              });
              // Cập nhật lại marker để thay đổi màu sắc
              _updateMarkers(restaurants);
            },
            child: Icon(
              Icons.location_pin,
              color: isSelected ? Colors.blueAccent : Colors.red,
              size: isSelected ? 50.0 : 40.0,
            ),
          ),
        ),
      );
    }
    if (mounted) {
      setState(() {
        _markers = loadedMarkers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(10.0333, 105.7833),
                    // Vị trí trung tâm Cần Thơ
                    initialZoom: 14.0,
                    onTap: (_, __) {
                      if (_selectedRestaurant != null) {
                        setState(() {
                          _selectedRestaurant = null;
                        });
                        _updateMarkers(_restaurants); // Cập nhật lại marker
                      }
                    },
                  ),
                  children: [
                    // Lớp nền của bản đồ
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.buaanyeuthuong', // Thay bằng package name của bạn
                    ),
                    // Lớp hiển thị các điểm đánh dấu (Marker)
                    MarkerLayer(markers: _markers.toList()),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                if (_selectedRestaurant != null) _buildRestaurantInfoCard(),
                Positioned(
                  bottom: _selectedRestaurant != null ? 200 : 20,
                  // Nâng các nút lên khi Card hiện ra
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'zoom_in', // Thêm heroTag để tránh lỗi
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom + 1,
                          );
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'zoom_out', // Thêm heroTag để tránh lỗi
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom - 1,
                          );
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRestaurantInfoCard() {
    // AnimatedPositioned sẽ tự động tạo hiệu ứng animation khi vị trí thay đổi
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: 10,
      left: 10,
      right: 10,
      child: GestureDetector(
        // Cho phép vuốt xuống để đóng Card
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
            // Vuốt xuống đủ nhanh
            setState(() {
              _selectedRestaurant = null;
            });
          }
        },
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Để Card chỉ chiếm không gian cần thiết
              children: [
                // Hàng trên cùng: Tên quán và nút đóng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedRestaurant!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedRestaurant = null;
                        });
                      },
                    ),
                  ],
                ),
                const Divider(),
                // Thông tin chi tiết
                Text(
                  _selectedRestaurant!.address,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (_selectedRestaurant!.suspendedMealsCount > 0)
                  Text(
                    'Đang có: ${_selectedRestaurant!.suspendedMealsCount} suất ăn treo',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 12),

                // Nút hành động
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => RestaurantDetailScreen(restaurant: _selectedRestaurant!),
                          ));
                        },
                        child: const Text('Xem chi tiết'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Chỉ đường'),
                        onPressed: () => _launchMapsUrl(_selectedRestaurant!.location.latitude, _selectedRestaurant!.location.longitude),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchMapsUrl(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lỗi khi mở bản đồ.')));
      }
    }
  }
}
