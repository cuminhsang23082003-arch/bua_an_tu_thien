import 'package:buaanyeuthuong/features/beneficiary/viewmodels/beneficiary_viewmodel.dart';
import 'package:buaanyeuthuong/features/meal_events/models/meal_event_model.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // (Tùy chọn: cần thêm vào pubspec.yaml nếu muốn dùng thật)

import '../../authentication/viewmodels/auth_viewmodel.dart';

class MealEventDetailScreen extends StatelessWidget {
  final MealEventModel mealEvent;

  const MealEventDetailScreen({Key? key, required this.mealEvent})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Thông tin chính (Hiển thị ngay, không cần chờ mạng)
                  _buildHeaderSection(context),

                  const Divider(height: 32, thickness: 1, color: Colors.grey),

                  // 2. Thông tin chi tiết địa điểm (Cần load thêm từ RestaurantRepo)
                  Text(
                    'Thông tin điểm phát',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildRestaurantDetails(context),

                  const SizedBox(height: 100), // Khoảng trống cho nút Bottom
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  // Header ảnh bìa mượt mà
  Widget _buildSliverAppBar(BuildContext context) {
    final restaurantRepo = context.read<RestaurantRepository>();

    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.orange,
      leading: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: FutureBuilder<RestaurantModel?>(
          future: restaurantRepo.getRestaurantById(mealEvent.restaurantId),
          builder: (context, snapshot) {
            // Hiển thị ảnh nếu có, hoặc placeholder
            if (snapshot.hasData && snapshot.data?.imageUrl != null) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    snapshot.data!.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                  // Lớp phủ gradient để ảnh đẹp hơn
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.transparent, Colors.black12],
                      ),
                    ),
                  ),
                ],
              );
            }
            return Container(
              color: Colors.orange.shade100,
              child: const Center(
                child: Icon(Icons.storefront, size: 80, color: Colors.orange),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    // Dùng getter status từ Model
    final isAvailable = mealEvent.remainingMeals > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge trạng thái
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isAvailable ? Colors.green : Colors.red),
          ),
          child: Text(
            isAvailable ? 'Đang phát' : 'Đã hết suất',
            style: TextStyle(
              color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          mealEvent.description,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(context, Icons.store, mealEvent.restaurantName, isBold: true),
        const SizedBox(height: 8),
        _buildInfoRow(
            context,
            Icons.calendar_today,
            '${DateFormat('EEEE, dd/MM/yyyy', 'vi').format(mealEvent.eventDate.toDate())}'
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, Icons.access_time, '${mealEvent.startTime} - ${mealEvent.endTime}'),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          Icons.restaurant_menu,
          'Còn lại: ${mealEvent.remainingMeals} / ${mealEvent.totalMealsOffered} suất',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildRestaurantDetails(BuildContext context) {
    final restaurantRepo = context.read<RestaurantRepository>();
    return FutureBuilder<RestaurantModel?>(
      future: restaurantRepo.getRestaurantById(mealEvent.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('Không tải được thông tin địa điểm.');
        }

        final restaurant = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.address,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                        Text(
                          '${restaurant.district}, ${restaurant.province}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    restaurant.phoneNumber,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Logic gọi điện (nếu cần)
                      // launchUrl(Uri.parse("tel:${restaurant.phoneNumber}"));
                    },
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Gọi'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    final authUser = context.watch<AuthViewModel>().currentUser;
    final bool isOutOfStock = mealEvent.remainingMeals <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Consumer<BeneficiaryViewModel>(
          builder: (context, viewModel, child) {
            return SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: (authUser == null || isOutOfStock || viewModel.isLoading)
                    ? null
                    : () async {
                  final error = await viewModel.registerForMeal(mealEvent, authUser);

                  if (context.mounted) {
                    if (error == null) {
                      // Thành công
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Column(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 60),
                              SizedBox(height: 12),
                              Text('Đăng ký thành công!', textAlign: TextAlign.center),
                            ],
                          ),
                          content: const Text(
                            'Mã vé đã được lưu vào mục "Vé ăn của tôi".\nVui lòng đến đúng giờ để nhận.',
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop(); // Đóng dialog
                                  Navigator.of(context).pop(); // Về danh sách
                                },
                                child: const Text('Đồng ý'),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Thất bại (Lỗi đã được làm sạch ở ViewModel)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  isOutOfStock
                      ? 'ĐÃ HẾT SUẤT'
                      : (authUser == null ? 'ĐĂNG NHẬP ĐỂ NHẬN' : 'ĐĂNG KÝ NHẬN NGAY'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, {bool isBold = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}