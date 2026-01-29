// lib/features/beneficiary/viewmodels/beneficiary_viewmodel.dart
import '../../authentication/models/user_model.dart';
import '../../meal_events/models/meal_event_model.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../repositories/registration_repository.dart';
import 'package:flutter/material.dart';

class BeneficiaryViewModel extends ChangeNotifier {
  final RegistrationRepository _registrationRepository;
  BeneficiaryViewModel({required RegistrationRepository registrationRepository})
      : _registrationRepository = registrationRepository;

  // Sử dụng một biến loading chung cho cả hai hành động
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Hàm đăng ký cho một đợt phát ăn cụ thể
  Future<String?> registerForMeal(MealEventModel mealEvent, UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _registrationRepository.registerForMealEvent(mealEvent, user);
      _isLoading = false;
      notifyListeners();
      return null; // Thành công, không có lỗi
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', ''); // Trả về thông báo lỗi đã được làm sạch
    }
  }

  // [HÀM MỚI] Hàm để nhận một suất ăn treo
  Future<String?> claimSuspendedMeal(RestaurantModel restaurant, UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Gọi đến hàm tương ứng trong repository
      await _registrationRepository.claimSuspendedMeal(restaurant, user);
      _isLoading = false;
      notifyListeners();
      return null; // Thành công
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', ''); // Thất bại
    }
  }
}