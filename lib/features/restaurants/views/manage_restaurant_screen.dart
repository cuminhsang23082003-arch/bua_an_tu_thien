// lib/features/restaurants/views/manage_restaurant_screen.dart
import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/dashboard/views/reports_screen.dart';
import 'package:buaanyeuthuong/features/meal_events/views/create_meal_event_screen.dart';
import 'package:buaanyeuthuong/features/meal_events/views/meal_events_list_screen.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/views/edit_restaurant_screen.dart';
import 'package:buaanyeuthuong/features/restaurants/views/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/views/stats_grid.dart';

class ManageRestaurantScreen extends StatelessWidget {
  final RestaurantModel restaurant;

  const ManageRestaurantScreen({Key? key, required this.restaurant})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      EditRestaurantScreen(initialRestaurant: restaurant),
                ),
              );
            },
            tooltip: 'Chỉnh sửa thông tin quán',
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Không'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // Đóng dialog
                        context.read<AuthViewModel>().signOut();
                      },
                      child: const Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StatsGrid(restaurant: restaurant),
            const SizedBox(height: 24),
            _buildRestaurantInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    // ... code drawer không thay đổi
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFFF6B6B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.storefront,
                    size: 30,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Tạo đợt phát ăn mới'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateMealEventScreen(restaurant: restaurant),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Các đợt phát suất ăn'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MealEventsListScreen(restaurantId: restaurant.id),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner_rounded),
            title: const Text('Quét mã Check-in'),
            onTap: () {
              Navigator.pop(context); // Đóng Drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Báo cáo & thống kê'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportsScreen(restaurant: restaurant),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ... Phần ảnh không thay đổi
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: restaurant.imageUrl != null
                ? Image.network(
                    restaurant.imageUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.storefront,
                        color: Colors.grey,
                        size: 80,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (restaurant.province.isNotEmpty)
                  _buildInfoRow(
                    'Khu vực',
                    Icons.map_outlined,
                    '${restaurant.district}, ${restaurant.province}',
                  ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Địa chỉ',
                  Icons.location_on_outlined,
                  restaurant.address,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Điện thoại',
                  Icons.phone_outlined,
                  restaurant.phoneNumber,
                ),
                const Divider(height: 24),
                _buildMultiLineInfo(
                  'Giờ hoạt động',
                  Icons.access_time_rounded,
                  restaurant.operatingHours,
                ),
                if (restaurant.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Mô tả',
                    Icons.description_outlined,
                    restaurant.description,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget con cho một dòng thông tin - ĐÃ SỬA LẠI
  Widget _buildInfoRow(String label, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              // Style mặc định cho cả dòng
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
              children: <TextSpan>[
                // Style riêng cho phần nhãn (in đậm)
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // Style riêng cho phần dữ liệu
                TextSpan(
                  text: text,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget con cho thông tin nhiều dòng (giờ hoạt động) - ĐÃ SỬA LẠI
  Widget _buildMultiLineInfo(
    String label,
    IconData icon,
    Map<String, String> data,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Dữ liệu key trong Firestore của bạn có thể là "Thứ Hai" hoặc "Thứ hai".
    // Để code mạnh mẽ hơn, chúng ta sẽ không dùng danh sách cứng nữa mà sắp xếp
    // dựa trên một map ánh xạ.
    const dayOrderMap = {
      'Thứ Hai': 1,
      'Thứ Ba': 2,
      'Thứ Tư': 3,
      'Thứ Năm': 4,
      'Thứ Sáu': 5,
      'Thứ Bảy': 6,
      'Chủ Nhật': 7,
    };

    final sortedEntries = data.entries.toList()
      ..sort((a, b) {
        // Lấy thứ tự của mỗi ngày, nếu không tìm thấy thì cho xuống cuối
        final indexA = dayOrderMap[a.key] ?? 8;
        final indexB = dayOrderMap[b.key] ?? 8;
        return indexA.compareTo(indexB);
      });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị nhãn chính (in đậm)
              Text(
                '$label:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              // Hiển thị danh sách giờ
              ...sortedEntries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
                  child: Row(
                    children: [
                      // Dùng SizedBox để căn chỉnh các ngày thẳng hàng
                      SizedBox(
                        width: 70, // Đặt độ rộng cố định cho tên ngày
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Expanded để giờ hoạt động chiếm hết phần còn lại
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
