import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/beneficiary/models/registration_model.dart';
import 'package:buaanyeuthuong/features/beneficiary/repositories/registration_repository.dart';
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Vé ăn của tôi'), elevation: 0),
      body: authUser == null
          ? const Center(child: Text('Vui lòng đăng nhập.'))
          : StreamBuilder<List<RegistrationModel>>(
        stream: registrationRepo.getMyRegistrationsStream(authUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final registrations = snapshot.data ?? [];

          if (registrations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Bạn chưa có vé ăn nào.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: registrations.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              // [TỐI ƯU] Không dùng FutureBuilder nữa
              return _RegistrationCard(registration: registrations[index]);
            },
          );
        },
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final RegistrationModel registration;
  const _RegistrationCard({Key? key, required this.registration}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy SĐT từ ViewModel để hiển thị
    final userPhone = context.select<AuthViewModel, String?>((vm) => vm.currentUser?.phoneNumber);

    final isRegistered = registration.status == RegistrationStatus.registered;
    final isClaimed = registration.status == RegistrationStatus.claimed;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isRegistered) {
      statusColor = Colors.orange;
      statusText = "CHỜ NHẬN";
      statusIcon = Icons.hourglass_top;
    } else if (isClaimed) {
      statusColor = Colors.green;
      statusText = "ĐÃ NHẬN";
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.red;
      statusText = "ĐÃ HỦY";
      statusIcon = Icons.cancel;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Trạng thái + Ngày
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(registration.registeredAt.toDate()),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),

            // Nội dung chính (Lấy từ trường denormalized)
            Text(registration.eventDescription, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.storefront, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(registration.restaurantName, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(registration.eventTimeDisplay, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),

            // [QUAN TRỌNG] Hiển thị SĐT để đối chiếu với chủ quán
            if (isRegistered) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    const Text("SĐT nhận món: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                        userPhone ?? "Chưa cập nhật",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showQrDialog(context),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text("MÃ QR NHẬN SUẤT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Đưa mã này cho quán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: registration.id,
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
            Text(registration.id, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))],
      ),
    );
  }
}