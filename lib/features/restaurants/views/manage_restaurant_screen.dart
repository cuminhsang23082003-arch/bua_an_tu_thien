// lib/features/restaurants/views/manage_restaurant_screen.dart
import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/dashboard/views/reports_screen.dart';
import 'package:buaanyeuthuong/features/meal_events/views/create_meal_event_screen.dart';
import 'package:buaanyeuthuong/features/meal_events/views/meal_events_list_screen.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/views/edit_restaurant_screen.dart';
import 'package:buaanyeuthuong/features/restaurants/views/check_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/views/stats_grid.dart';

class ManageRestaurantScreen extends StatelessWidget {
  final RestaurantModel restaurant;

  const ManageRestaurantScreen({Key? key, required this.restaurant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          // 1. Header ảnh bìa mượt mà
          _buildSliverAppBar(context),

          // 2. Nội dung chính
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grid thống kê (Giữ nguyên logic của bạn)
                  StatsGrid(restaurant: restaurant),

                  const SizedBox(height: 24),

                  // Tiêu đề section
                  const Text(
                    "Thông tin quán",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Card thông tin chính
                  _buildMainInfoCard(context),

                  const SizedBox(height: 20),

                  // Card giờ hoạt động & Mô tả
                  _buildOperationCard(context),

                  const SizedBox(height: 80), // Khoảng trống dưới cùng
                ],
              ),
            ),
          ),
        ],
      ),
      // Nút tắt để tạo nhanh sự kiện (Tùy chọn)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CreateMealEventScreen(restaurant: restaurant)),
          );
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text("Tạo đợt phát"),
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.orange,
      actions: [
        IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.edit, color: Colors.white),
          ),
          tooltip: 'Chỉnh sửa',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditRestaurantScreen(initialRestaurant: restaurant)),
            );
          },
        ),
        IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.logout, color: Colors.white),
          ),
          tooltip: 'Đăng xuất',
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          restaurant.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            restaurant.imageUrl != null
                ? Image.network(
              restaurant.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(color: Colors.orange.shade200),
            )
                : Container(
              color: Colors.orange.shade300,
              child: const Icon(Icons.store, size: 80, color: Colors.white54),
            ),
            // Lớp phủ gradient để text dễ đọc hơn
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                  stops: [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoRowModern(
              icon: Icons.location_on,
              color: Colors.red,
              title: "Địa chỉ",
              content: "${restaurant.address}, ${restaurant.district}, ${restaurant.province}",
            ),
            const Divider(height: 24, thickness: 1, color: Colors.grey),
            _buildInfoRowModern(
                icon: Icons.person,
                color: Colors.brown,
                title: "Chủ quán",
            content: restaurant.ownerName),
            const Divider(height: 24, thickness: 1, color: Colors.grey),
            _buildInfoRowModern(
              icon: Icons.phone,
              color: Colors.blue,
              title: "Hotline",
              content: restaurant.phoneNumber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRowModern(
              icon: Icons.access_time_filled,
              color: Colors.green,
              title: "Giờ hoạt động",
              customContent: _buildOperatingHoursColumn(restaurant.operatingHours),
            ),
            if (restaurant.description.isNotEmpty) ...[
              const Divider(height: 30),
              _buildInfoRowModern(
                icon: Icons.info,
                color: Colors.amber,
                title: "Giới thiệu",
                content: restaurant.description,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowModern({
    required IconData icon,
    required Color color,
    required String title,
    String? content,
    Widget? customContent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              customContent ??
                  Text(
                    content ?? "",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHoursColumn(Map<String, String> data) {
    if (data.isEmpty) return const Text("Chưa cập nhật", style: TextStyle(color: Colors.grey));

    const dayOrderMap = {
      'Thứ Hai': 1, 'Thứ Ba': 2, 'Thứ Tư': 3, 'Thứ Năm': 4,
      'Thứ Sáu': 5, 'Thứ Bảy': 6, 'Chủ Nhật': 7,
    };

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => (dayOrderMap[a.key] ?? 8).compareTo(dayOrderMap[b.key] ?? 8));

    return Column(
      children: sortedEntries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(entry.value, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- DRAWER (Giữ nguyên Logic, chỉ chỉnh nhẹ UI) ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
            ),
            accountName: Text(restaurant.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: const Text("Bảng quản trị viên"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: restaurant.imageUrl != null ? NetworkImage(restaurant.imageUrl!) : null,
              child: restaurant.imageUrl == null ? const Icon(Icons.store, color: Colors.orange) : null,
            ),
          ),
          _buildDrawerItem(context, Icons.add_circle_outline, 'Tạo đợt phát ăn mới', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateMealEventScreen(restaurant: restaurant)));
          }),
          _buildDrawerItem(context, Icons.event_note_outlined, 'Quản lý đợt phát', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealEventsListScreen(restaurantId: restaurant.id)));
          }),
          const Divider(),
          _buildDrawerItem(context, Icons.qr_code_scanner_rounded, 'Quét mã Check-in', () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckInScreen(restaurant: restaurant)));
          }),
          _buildDrawerItem(context, Icons.analytics_outlined, 'Báo cáo & Thống kê', () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportsScreen(restaurant: restaurant)));
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn thoát phiên làm việc?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthViewModel>().signOut();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}