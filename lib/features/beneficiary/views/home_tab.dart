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
    _initLocation();
  }

  Future<void> _initLocation() async {
    // 1. Thử lấy vị trí cuối cùng được biết (Nhanh)
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _currentPosition = lastPos;
          _isLoadingPosition = false; // Hiển thị nội dung ngay
        });
      }
    } catch (_) {}

    // 2. Lấy vị trí chính xác hiện tại (Chậm hơn nhưng chuẩn hơn)
    try {
      final position = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingPosition = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPosition = false);
      // Xử lý lỗi (ví dụ chưa bật GPS) nếu cần
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
            onPressed: () {
              // TODO: Mở màn hình thông báo
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoadingPosition = true);
          await _initLocation();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            _buildHeader(),
            _buildRecentEventsSection(context),
            const Divider(height: 32, thickness: 8, color: Colors.white), // Dải phân cách
            _buildSuspendedMealsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chào mừng bạn trở lại! ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Cùng nhau chia sẻ bữa ăn, lan tỏa yêu thương.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsSection(BuildContext context) {
    final mealEventRepo = context.read<MealEventRepository>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gần bạn nhất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllEventsScreen())),
                child: const Text('Xem tất cả', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        if (_isLoadingPosition && _currentPosition == null)
          const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),

        StreamBuilder<List<MealEventModel>>(
          stream: mealEventRepo.getAllActiveMealEventsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _currentPosition == null) {
              return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
            }

            final allEvents = snapshot.data ?? [];

            // Lọc sự kiện hợp lệ
            final validEvents = allEvents.where((event) {
              final status = event.effectiveStatus;
              return status == MealEventStatus.scheduled || status == MealEventStatus.ongoing;
            }).toList();

            if (validEvents.isEmpty) {
              return Container(
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Chưa có đợt phát ăn nào đang diễn ra.', style: TextStyle(color: Colors.grey))),
              );
            }

            // Sắp xếp theo khoảng cách (nếu có vị trí)
            if (_currentPosition != null) {
              validEvents.sort((a, b) {
                final dA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, a.location.latitude, a.location.longitude);
                final dB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, b.location.latitude, b.location.longitude);
                return dA.compareTo(dB);
              });
            }

            final displayEvents = validEvents.take(5).toList();

            return SizedBox(
              height: 200, // Tăng chiều cao để thẻ thoải mái hơn
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayEvents.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildRecentEventCard(context, displayEvents[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentEventCard(BuildContext context, MealEventModel event) {
    String distanceText = '---';
    if (_currentPosition != null) {
      final distanceM = Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude,
          event.location.latitude, event.location.longitude);
      distanceText = '${(distanceM / 1000).toStringAsFixed(1)} km';
    }

    final isAvailable = event.remainingMeals > 0;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealEventDetailScreen(mealEvent: event))),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(distanceText, style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!isAvailable)
                      const Text('Hết suất', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(event.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(event.restaurantName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),

                const Spacer(),
                const Divider(),

                Row(children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(DateFormat('dd/MM').format(event.eventDate.toDate()), style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${event.startTime} - ${event.endTime}', style: const TextStyle(fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.restaurant_menu, size: 14, color: isAvailable ? Colors.green : Colors.red),
                  const SizedBox(width: 6),
                  Text('Còn ${event.remainingMeals} suất', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isAvailable ? Colors.green : Colors.red)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuspendedMealsSection(BuildContext context) {
    final restaurantRepo = context.read<RestaurantRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text('Suất ăn treo miễn phí', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<List<RestaurantModel>>(
          stream: restaurantRepo.getRestaurantsWithSuspendedMealsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final restaurants = snapshot.data ?? [];
            if (restaurants.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Hiện chưa có quán nào có suất ăn treo.', style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: restaurants.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildSuspendedMealTile(context, restaurants[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuspendedMealTile(BuildContext context, RestaurantModel restaurant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: restaurant))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
            image: restaurant.imageUrl != null
                ? DecorationImage(image: NetworkImage(restaurant.imageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: restaurant.imageUrl == null ? const Icon(Icons.store, color: Colors.blue) : null,
        ),
        title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(
          '${restaurant.district}, ${restaurant.province}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${restaurant.suspendedMealsCount}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800)),
              Text('suất treo', style: TextStyle(fontSize: 10, color: Colors.green.shade800)),
            ],
          ),
        ),
      ),
    );
  }
}