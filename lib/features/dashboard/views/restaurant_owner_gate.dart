// lib/features/dashboard/views/restaurant_owner_gate.dart
import 'package:buaanyeuthuong/features/authentication/models/user_model.dart';
import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:buaanyeuthuong/features/restaurants/views/create_restaurant_screen.dart';
import 'package:buaanyeuthuong/features/restaurants/views/manage_restaurant_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RestaurantOwnerGate extends StatelessWidget {
  const RestaurantOwnerGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserModel? user = context.watch<AuthViewModel>().currentUser;

    if (user == null) {
      // Có thể hiển thị màn hình lỗi hoặc loading tinh tế hơn
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final restaurantRepo = context.read<RestaurantRepository>();

    return StreamBuilder<RestaurantModel?>(
      stream: restaurantRepo.getRestaurantStreamByOwner(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Lỗi: ${snapshot.error}')));
        }

        final restaurant = snapshot.data;

        if (restaurant == null) {
          // [SỬA ĐỔI QUAN TRỌNG]
          // Truyền đối tượng user vào constructor của CreateRestaurantScreen
          return CreateRestaurantScreen(owner: user);
        } else {
          return ManageRestaurantScreen(restaurant: restaurant);
        }
      },
    );
  }
}