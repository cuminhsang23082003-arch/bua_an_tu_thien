// lib/features/restaurants/views/restaurant_detail_screen.dart
import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/beneficiary/viewmodels/beneficiary_viewmodel.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({Key? key, required this.restaurant})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng lại SliverAppBar cho đẹp
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (restaurant.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      restaurant.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    Icons.location_on_outlined,
                    '${restaurant.district}, ${restaurant.province}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    Icons.location_city_outlined,
                    restaurant.address,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    Icons.phone_forwarded_outlined,
                    restaurant.phoneNumber,
                  ),
                  const Divider(height: 32),
                  _buildMultiLineInfo(
                    context,
                    Icons.access_time_rounded,
                    restaurant.operatingHours,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Nút nhận suất ăn treo
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: restaurant.imageUrl != null
            ? Image.network(
                restaurant.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => _placeholderImage(),
              )
            : _placeholderImage(),
      ),
    );
  }

  Widget _placeholderImage() => Container(
    color: Colors.grey.shade300,
    child: const Icon(Icons.storefront, size: 100, color: Colors.grey),
  );

  Widget _buildBottomButton(BuildContext context) {
    final authUser = context.watch<AuthViewModel>().currentUser;
    final restaurantStream = context
        .watch<RestaurantRepository>()
        .getRestaurantStreamById(restaurant.id);

    return StreamBuilder<RestaurantModel?>(
      stream: restaurantStream,
      builder: (context, snapshot) {
        final currentCount =
            snapshot.data?.suspendedMealsCount ??
            restaurant.suspendedMealsCount;
        return Consumer<BeneficiaryViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.card_giftcard),
                      label: Text('Nhận suất ăn treo (còn $currentCount suất)'),
                      onPressed: (authUser == null || currentCount <= 0)
                          ? null // Vô hiệu hóa nút
                          : () async {
                              final error = await viewModel.claimSuspendedMeal(
                                restaurant,
                                authUser,
                              );
                              if (context.mounted) {
                                if (error == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đăng ký nhận suất ăn treo thành công!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
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
                        backgroundColor: Colors.green, // Màu khác để phân biệt
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  // Tái sử dụng widget này
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget _buildMultiLineInfo(
    BuildContext context,
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
                'Giờ hoạt động:',
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
