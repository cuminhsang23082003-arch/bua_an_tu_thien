// lib/features/beneficiary/views/my_registrations_tab.dart
import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/beneficiary/models/registration_model.dart';
import 'package:buaanyeuthuong/features/beneficiary/repositories/registration_repository.dart';
import 'package:buaanyeuthuong/features/meal_events/models/meal_event_model.dart';
import 'package:buaanyeuthuong/features/meal_events/repositories/meal_event_repository.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';

class MyRegistrationsTab extends StatelessWidget {
  const MyRegistrationsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final registrationRepo = context.read<RegistrationRepository>();
    final authUser = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Hoạt động của tôi')),
      body: authUser == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem.'))
          : StreamBuilder<List<RegistrationModel>>(
        stream: registrationRepo.getMyRegistrationsStream(authUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Đã có lỗi xảy ra.'));
          }
          final registrations = snapshot.data ?? [];
          if (registrations.isEmpty) {
            return const Center(child: Text('Bạn chưa đăng ký suất ăn nào.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              return RegistrationInfoCard(registration: registrations[index]);
            },
          );
        },
      ),
    );
  }
}

class RegistrationInfoCard extends StatelessWidget {
  final RegistrationModel registration;
  const RegistrationInfoCard({Key? key, required this.registration}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSuspendedMealClaim = registration.mealEventId.isEmpty;
    if (isSuspendedMealClaim) {
      return _buildSuspendedMealCard(context);
    } else {
      return _buildMealEventCard(context);
    }
  }

  // Widget cho Card suất ăn treo - ĐÃ SỬA LẠI
  Widget _buildSuspendedMealCard(BuildContext context) {
    final restaurantRepo = context.read<RestaurantRepository>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: FutureBuilder<RestaurantModel?>(
        future: restaurantRepo.getRestaurantById(registration.restaurantId),
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
          }
          final restaurantName = snapshot.data?.name ?? 'Quán ăn không xác định';

          // [SỬA LỖI] Bọc nội dung trong Padding
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Suất ăn treo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text('Tại: $restaurantName', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                const Divider(height: 20),
                Text('Ngày đăng ký: ${DateFormat('dd/MM/yyyy').format(registration.registeredAt.toDate())}'),
                const SizedBox(height: 16),
                _buildActionWidget(context),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget cho Card đợt phát ăn
  Widget _buildMealEventCard(BuildContext context) {
    final mealEventRepo = context.read<MealEventRepository>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: FutureBuilder<MealEventModel?>(
        future: mealEventRepo.getMealEventById(registration.mealEventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == null) {
            return ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('Thông tin đợt phát ăn không còn tồn tại.'),
              subtitle: Text('ID: ${registration.mealEventId}'),
            );
          }
          final mealEvent = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mealEvent.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text('Tại: ${mealEvent.restaurantName}', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                const Divider(height: 20),
                Text('Ngày nhận: ${DateFormat('dd/MM/yyyy').format(mealEvent.eventDate.toDate())}'),
                Text('Thời gian: ${mealEvent.startTime} - ${mealEvent.endTime}'),
                const SizedBox(height: 16),
                _buildActionWidget(context),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget chung để hiển thị nút QR hoặc Chip trạng thái
  Widget _buildActionWidget(BuildContext context) {
    return Center(
      child: registration.status == RegistrationStatus.registered
          ? SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.qr_code_2_rounded),
          label: const Text('Hiển thị mã nhận'),
          onPressed: () => _showQrCodeDialog(context, registration.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      )
          : Chip(
        label: Text(
          registration.status == RegistrationStatus.claimed ? 'ĐÃ NHẬN' : 'ĐÃ HỦY',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: registration.status == RegistrationStatus.claimed ? Colors.green.shade400 : Colors.red.shade300,
      ),
    );
  }

  void _showQrCodeDialog(BuildContext context, String registrationId) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            contentPadding: const EdgeInsets.all(24.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Đưa mã này cho nhân viên để xác nhận nhận suất ăn',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: QrImageView(
                    data: registrationId,
                    version: QrVersions.auto,
                    gapless: false,
                    // Để có viền trắng đẹp hơn
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  registrationId,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }
}



