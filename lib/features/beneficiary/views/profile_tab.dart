// lib/features/profile/views/profile_tab.dart
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
    // Dùng .watch để widget tự cập nhật nếu thông tin người dùng thay đổi
    final UserModel? user = context
        .watch<AuthViewModel>()
        .currentUser;

    // Hiển thị loading nếu chưa có thông tin user
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ghép chuỗi địa chỉ đầy đủ
    String fullAddress = [
      user.address,
      user.district,
      user.province,
    ].where((s) => s != null && s.isNotEmpty).join(
        ', '); // Lọc bỏ phần rỗng và nối lại

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của bạn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Lấy user từ Provider để truyền đi
              final user = context
                  .read<AuthViewModel>()
                  .currentUser;
              if (user != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: user),
                  ),
                );
              }
            },
            tooltip: 'Chỉnh sửa hồ sơ',
          ),
        ],
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Avatar
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFFF6B6B),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              // Tên hiển thị
              Text(
                user.displayName,
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Email
              Text(
                user.email,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              // Vai trò
              Chip(
                label: Text(user.role.displayName),
                backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 40),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded, color: Colors.grey),
                title: const Text('Lịch sử quyên góp'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const DonationHistoryScreen(),));
                },
              ),
              _buildProfileInfoRow(Icons.phone_outlined, 'Điện thoại',
                  user.phoneNumber ?? 'Chưa cập nhật'),
              const SizedBox(height: 12),
              _buildProfileInfoRow(Icons.home_outlined, 'Địa chỉ',
                  fullAddress.isEmpty ? 'Chưa cập nhật' : fullAddress),
              const Spacer(), // Đẩy nút Đăng xuất xuống dưới cùng
              // Nút Đăng xuất
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  onPressed: () {
                    // Hiển thị dialog xác nhận trước khi đăng xuất
                    showDialog(
                      context: context,
                      builder: (ctx) =>
                          AlertDialog(
                            title: const Text('Xác nhận đăng xuất'),
                            content: const Text(
                              'Bạn có chắc chắn muốn đăng xuất không?',
                            ),
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      // Dùng CrossAxisAlignment.start để icon và text được căn lề trên cùng
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Thêm padding để icon không bị dính sát lề trên nếu text xuống dòng
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, color: Colors.grey.shade600, size: 20),
        ),
        const SizedBox(width: 16),
        // [SỬA ĐỔI QUAN TRỌNG] Bọc Column trong Expanded
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              // Text widget này bây giờ sẽ tự động xuống dòng nếu cần
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
