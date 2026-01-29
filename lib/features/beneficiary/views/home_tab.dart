// lib/features/beneficiary/views/home_tab.dart
import 'package:buaanyeuthuong/features/core/services/location_service.dart';
import 'package:buaanyeuthuong/features/meal_events/models/meal_event_model.dart';
import 'package:buaanyeuthuong/features/meal_events/repositories/meal_event_repository.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:buaanyeuthuong/features/restaurants/views/restaurant_detail_screen.dart';
import 'package:buaanyeuthuong/features/beneficiary/views/all_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'meal_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoadingPosition = true;
  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _isLoadingPosition = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: ListView(
        children: [
          _buildHeader(),
          _buildRecentEventsSection(context),
          _buildSuspendedMealsSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào mừng bạn trở lại!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy cùng khám phá các bữa ăn yêu thương nhé.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsSection(BuildContext context) {
    final mealEventRepo = context.read<MealEventRepository>();

    if (_isLoadingPosition) {
      return const SizedBox(height: 220, child: Center(child: Text('Đang xác định vị trí của bạn...')));
    }
    if (_currentPosition == null) {
      return const SizedBox(height: 100, child: Center(child: Text('Không thể xác định vị trí.')));
    }



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Đợt phát suất ăn gần bạn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllEventsScreen())),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
        ),
        StreamBuilder<List<MealEventModel>>(
          // [SỬA LỖI] Lấy TẤT CẢ các sự kiện về để có thể sắp xếp
          stream: mealEventRepo.getAllActiveMealEventsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(height: 100, child: Center(child: Text('Không có đợt phát ăn nào gần đây.')));
            }

            var allEvents = snapshot.data!;

            final validEvents = allEvents.where((event) {
              final status = event.effectiveStatus;
              return status == MealEventStatus.scheduled || status == MealEventStatus.ongoing;
            }).toList();

            // Lọc và sắp xếp theo khoảng cách
            validEvents.sort((a, b) {
              final distanceA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, a.location.latitude, a.location.longitude);
              final distanceB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, b.location.latitude, b.location.longitude);
              return distanceA.compareTo(distanceB);
            });

            // Lấy 5 sự kiện gần nhất
            final nearestEvents = validEvents.take(5).toList();

            return SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: nearestEvents.length,
                itemBuilder: (context, index) {
                  // [SỬA LỖI] Truyền _currentPosition vào đây
                  return _buildRecentEventCard(context, nearestEvents[index], _currentPosition!);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuspendedMealsSection(BuildContext context) {
    final restaurantRepo = context.read<RestaurantRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Điểm có suất ăn treo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<List<RestaurantModel>>(
          stream: restaurantRepo.getRestaurantsWithSuspendedMealsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Chưa có quán nào có suất ăn treo.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            final restaurants = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                return _buildSuspendedMealRestaurantTile(
                  context,
                  restaurants[index],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentEventCard(BuildContext context, MealEventModel event,  Position userPosition) {
    final distanceInMeters = Geolocator.distanceBetween(userPosition.latitude, userPosition.longitude, event.location.latitude, event.location.longitude);
    final distanceInKm = (distanceInMeters / 1000).toStringAsFixed(1);

    return SizedBox(
      width: 260,
      child: Card(
        margin: const EdgeInsets.all(6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealEventDetailScreen(mealEvent: event))),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(event.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('$distanceInKm km', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(event.restaurantName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today_outlined, DateFormat('dd/MM/yyyy').format(event.eventDate.toDate())),
                const SizedBox(height: 5),
                _buildInfoRow(Icons.access_time_outlined, '${event.startTime} - ${event.endTime}'),
                const SizedBox(height: 5),
                _buildInfoRow(Icons.restaurant_menu_outlined, 'Còn ${event.remainingMeals} suất'),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildSuspendedMealRestaurantTile(
    BuildContext context,
    RestaurantModel restaurant,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: const Icon(Icons.storefront)),
        title: Text(
          restaurant.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${restaurant.district}, ${restaurant.province}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${restaurant.suspendedMealsCount}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Text(
              'suất treo',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        ),
      ),
    );
  }
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 15), overflow: TextOverflow.ellipsis)),
      ],
    );
  }


}
