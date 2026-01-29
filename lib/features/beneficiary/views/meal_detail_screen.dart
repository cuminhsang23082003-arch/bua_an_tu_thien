// lib/features/beneficiary/views/meal_detail_screen.dart
import 'package:buaanyeuthuong/features/beneficiary/viewmodels/beneficiary_viewmodel.dart';
import 'package:buaanyeuthuong/features/meal_events/models/meal_event_model.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../authentication/viewmodels/auth_viewmodel.dart';

class MealEventDetailScreen extends StatelessWidget {
  final MealEventModel mealEvent;
  const MealEventDetailScreen({Key? key, required this.mealEvent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar với ảnh nền
          _buildSliverAppBar(context),

          // Nội dung chi tiết
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealEvent.description,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, Icons.storefront_outlined, 'Phát tại: ${mealEvent.restaurantName}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, Icons.calendar_today_outlined, 'Ngày: ${DateFormat('dd/MM/yyyy').format(mealEvent.eventDate.toDate())}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, Icons.access_time_outlined, 'Thời gian: ${mealEvent.startTime} - ${mealEvent.endTime}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, Icons.restaurant_menu_outlined, 'Số suất còn lại: ${mealEvent.remainingMeals}'),
                  const Divider(height: 40),
                  Text(
                    'Thông tin thêm về điểm phát',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildRestaurantDetails(context),
                ],
              ),
            ),
          )
        ],
      ),
      // Nút Đăng ký nhận ở dưới cùng
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final restaurantRepo = context.read<RestaurantRepository>();
    return FutureBuilder<RestaurantModel?>(
        future: restaurantRepo.getRestaurantById(mealEvent.restaurantId),
        builder: (context, snapshot)
    {
      final restaurantImage = snapshot.data?.imageUrl;
      return SliverAppBar(
        expandedHeight: 250.0,
        pinned: true,
        stretch: true,

        leading: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back,color: Colors.white),
          ),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: restaurantImage != null
              ? Image.network(
            restaurantImage,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, st) =>
            const Icon(Icons.storefront,
                size: 100, color: Colors.grey),
          )
              : Container(color: Colors.grey.shade300, child: const
          Icon(Icons.food_bank_outlined, size: 100, color: Colors.grey)),
        ),
      );
    },);
  }

  Widget _buildRestaurantDetails(BuildContext context) {
    final restaurantRepo = context.read<RestaurantRepository>();
    return FutureBuilder<RestaurantModel?>(
      future: restaurantRepo.getRestaurantById(mealEvent.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('Không tìm thấy thông tin điểm phát.');
        }
        final restaurant = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, Icons.location_city_outlined, restaurant.address),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.phone_forwarded_outlined, restaurant.phoneNumber),
          ],
        );
      },
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    final authUser = context.watch<AuthViewModel>().currentUser;

    return Consumer<BeneficiaryViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Đăng ký nhận'),
            // Điều kiện vô hiệu hóa nút
            onPressed: (authUser == null || mealEvent.remainingMeals <= 0)
                ? null
                : () async {
              // [SỬA LỖI] Logic được viết lại cho đúng cú pháp

              // 1. Gọi hàm và chờ kết quả
              final error = await viewModel.registerForMeal(mealEvent, authUser);

              // 2. Sau khi có kết quả, kiểm tra context và xử lý
              if (context.mounted) {
                if (error == null) {
                  // Thành công
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Không cho đóng dialog bằng cách nhấn ra ngoài
                    builder: (ctx) => AlertDialog(
                      title: const Text('Đăng ký thành công!'),
                      content: const Text('Vui lòng đến đúng giờ để nhận suất ăn nhé.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop(); // Đóng dialog
                            Navigator.of(context).pop(); // Quay về danh sách
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Thất bại
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}