// lib/features/profile/viewmodels/profile_viewmodel.dart
import 'package:buaanyeuthuong/features/authentication/repositories/auth_repository.dart';
import 'package:flutter/material.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  ProfileViewModel({required AuthRepository authRepository}) : _authRepository = authRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> updateProfile(String uid, String newDisplayName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.updateUserData(uid: uid, displayName: newDisplayName,);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Cập nhật thất bại: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}