// lib/features/dashboard/views/dashboard_router.dart

import 'package:buaanyeuthuong/features/beneficiary/views/beneficiary_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:buaanyeuthuong/features/authentication/models/user_model.dart'; // Thay your_app_name
import 'restaurant_owner_gate.dart'; // Import file vừa tạo

class DashboardRouter extends StatelessWidget {
  final UserModel user;
  const DashboardRouter({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy vai trò của người dùng
    final userRole = user.role;

    // *** LOGIC PHÂN VAI TRÒ ***
    switch (userRole) {
      case UserRole.restaurantOwner:
      // Nếu là chủ quán, hiển thị "Cổng" quản lý
        return const RestaurantOwnerGate();

      case UserRole.beneficiary:
      // Placeholder cho các vai trò khác
        return const BeneficiaryDashboard();

      case UserRole.volunteer:
        return const Scaffold(body: Center(child: Text('Giao diện Tình Nguyện Viên')));

      default:
        return const Scaffold(body: Center(child: Text('Vai trò không xác định.')));
    }
  }
}