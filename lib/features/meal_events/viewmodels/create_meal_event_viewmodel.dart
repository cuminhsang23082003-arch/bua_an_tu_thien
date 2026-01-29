// lib/features/meal_events/viewmodels/create_meal_event_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../models/meal_event_model.dart';
import '../repositories/meal_event_repository.dart';

class CreateMealEventViewModel extends ChangeNotifier {
  final MealEventRepository _mealEventRepository;

  CreateMealEventViewModel({required MealEventRepository mealEventRepository})
      : _mealEventRepository = mealEventRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> createMealEvent({
    required RestaurantModel restaurant, // Cần thông tin quán để denormalize
    required String description,
    required int totalMeals,
    required DateTime eventDate,
    required String startTime,
    required String endTime,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newEvent = MealEventModel(
        id: '', // Firestore sẽ tự tạo
        restaurantId: restaurant.id,
        restaurantName: restaurant.name, // Denormalization
        province: restaurant.province,
        district: restaurant.district,
        location: restaurant.location,
        eventDate: Timestamp.fromDate(eventDate),
        startTime: startTime,
        endTime: endTime,
        totalMealsOffered: totalMeals,
        remainingMeals: totalMeals, // Ban đầu số lượng còn lại bằng tổng số
        mealType: MealEventType.free_meal, // Mặc định cho giai đoạn 1
        description: description,
        status: MealEventStatus.scheduled,
        registeredRecipientsCount: 0,
        createdAt: Timestamp.now(),
      );

      await _mealEventRepository.createMealEvent(newEvent);

      _isLoading = false;
      notifyListeners();
      return true; // Thành công
    } catch (e) {
      _errorMessage = "Lỗi khi tạo đợt phát ăn: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false; // Thất bại
    }
  }
}