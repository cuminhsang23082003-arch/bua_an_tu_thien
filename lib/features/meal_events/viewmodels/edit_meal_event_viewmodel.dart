// lib/features/meal_events/viewmodels/edit_meal_event_viewmodel.dart
import 'package:buaanyeuthuong/features/meal_events/models/meal_event_model.dart';
import 'package:buaanyeuthuong/features/meal_events/repositories/meal_event_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditMealEventViewModel extends ChangeNotifier {
  final MealEventRepository _mealEventRepository;

  EditMealEventViewModel({required MealEventRepository mealEventRepository})
      : _mealEventRepository = mealEventRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> updateMealEvent({
    required MealEventModel originalEvent,
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
      // Dùng copyWith để tạo một đối tượng mới với các thông tin đã được cập nhật
      final updatedEvent = originalEvent.copyWith(
        description: description,
        totalMealsOffered: totalMeals,
        // Khi sửa, chúng ta cũng nên reset lại số lượng còn lại
        remainingMeals: totalMeals,
        eventDate: Timestamp.fromDate(eventDate),
        startTime: startTime,
        endTime: endTime,
      );

      await _mealEventRepository.updateMealEvent(updatedEvent);

      _isLoading = false;
      notifyListeners();
      return true; // Thành công
    } catch (e) {
      _errorMessage = "Lỗi khi cập nhật đợt phát ăn: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false; // Thất bại
    }
  }
}