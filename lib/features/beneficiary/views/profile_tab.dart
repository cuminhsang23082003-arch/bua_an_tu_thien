import 'package:buaanyeuthuong/features/authentication/models/user_model.dart';
import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/beneficiary/views/edit_profile_screen.dart';
import 'package:buaanyeuthuong/features/donations/views/donation_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserModel? user = context.watch<AuthViewModel>().currentUser;

    if (user == null) return const Center(child: CircularProgressIndicator());

    String fullAddress = [user.address, user.district, user.province]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    // Kiểm tra có SĐT chưa
    final bool hasPhone = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của bạn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)));
            },
            tooltip: 'Chỉnh sửa hồ sơ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFFF6B6B),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(user.email, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              Chip(
                label: Text(user.role.displayName),
                backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.1),
                labelStyle: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
              ),
              const Divider(height: 40),

              // [MỚI] Cảnh báo nếu chưa có SĐT
              if (!hasPhone)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Vui lòng cập nhật Số điện thoại để có thể nhận suất ăn mà không cần mang theo vé QR.",
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildProfileInfoRow(Icons.phone_outlined, 'Điện thoại', user.phoneNumber ?? 'Chưa cập nhật'),
              const SizedBox(height: 12),
              _buildProfileInfoRow(Icons.home_outlined, 'Địa chỉ', fullAddress.isEmpty ? 'Chưa cập nhật' : fullAddress),

              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded, color: Colors.grey),
                title: const Text('Lịch sử quyên góp'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonationHistoryScreen())),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  onPressed: () => _showLogoutDialog(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Không')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthViewModel>().signOut();
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2.0), child: Icon(icon, color: Colors.grey.shade600, size: 20)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}