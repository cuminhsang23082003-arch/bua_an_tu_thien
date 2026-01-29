// lib/features/authentication/viewmodels/auth_viewmodel.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error, // Giữ lại state này để xử lý các lỗi nghiêm trọng
}

class AuthViewModel with ChangeNotifier {
  final AuthRepository _authRepository;

  // [FIX 1] Lưu lại StreamSubscription để có thể hủy nó.
  StreamSubscription? _authSubscription;

  AuthStatus _status = AuthStatus.initial; // Bắt đầu bằng initial rõ ràng hơn
  String _errorMessage = '';
  UserModel? _currentUser;

  AuthStatus get status => _status;

  String get errorMessage => _errorMessage;

  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository {
    _listenToAuthChanges();
  }

  // [FIX 1] Hủy subscription khi ViewModel bị dispose để tránh memory leak.
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _listenToAuthChanges() {
    // Bắt đầu loading khi kiểm tra trạng thái lần đầu
    if (_status == AuthStatus.initial) {
      _updateStatus(AuthStatus.loading);
    }

    _authSubscription = _authRepository.authStateChanges.listen((
      User? firebaseUser,
    ) async {
      if (firebaseUser == null) {
        _currentUser = null;
        // Listener là nguồn chân lý duy nhất, khi user null -> unauthenticated.
        _updateStatus(AuthStatus.unauthenticated);
        return;
      }
      try {
        final userModel = await _authRepository.getUserData(firebaseUser.uid);
        if (userModel != null) {
          _currentUser = userModel;
          _updateStatus(AuthStatus.authenticated);
        } else {
          // Lỗi nghiêm trọng: có user trong Auth nhưng không có trong Firestore.
          await _authRepository.signOut();
          _updateStatus(
            AuthStatus.error,
            'Dữ liệu người dùng không đồng bộ. Vui lòng đăng nhập lại.',
          );
        }
      } catch (e) {
        _currentUser = null;
        _updateStatus(AuthStatus.error, 'Lỗi khi lấy dữ liệu người dùng.');
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    await _executeAuthAction(() async {
      await _authRepository.signIn(email: email, password: password);
      // Listener sẽ tự động xử lý việc chuyển sang authenticated.
    });
  }

  // [REFINEMENT 2] Hàm signUp được làm gọn, tin tưởng vào listener.
  Future<void> signUp(
      String displayName,
      String email,
      String password,
      UserRole role,
      String phoneNumber,
      ) async {
    _updateStatus(AuthStatus.loading);
    try {
      // 1. Kiểm tra SĐT
      if (phoneNumber.isNotEmpty) {
        final bool phoneExists = await _authRepository.isPhoneNumberExists(phoneNumber);
        if (phoneExists) {
          throw Exception("Số điện thoại này đã được sử dụng.");
        }
      }

      // 2. Tạo tài khoản (Firebase tự kiểm tra email)
      final userCredential = await _authRepository.signUp(
        email: email,
        password: password,
      );

      // 3. Lưu dữ liệu vào Firestore
      final newUser = UserModel.fromFirebaseUser(
        userCredential.user!,
        role,
        displayName: displayName,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
      );
      await _authRepository.saveUserDataToFirestore(newUser);


    } on FirebaseAuthException catch (e) {
      _updateStatus(AuthStatus.error, _handleAuthError(e.code));
      throw e;
    } catch (e) {
      _updateStatus(AuthStatus.error, e.toString().replaceFirst('Exception: ', ''));
      throw e;
    }
  }

  Future<void> signOut() async {
    // Không cần _executeAuthAction vì logic khá đơn giản
    try {
      await _authRepository.signOut();
      // Listener sẽ tự động chuyển state về unauthenticated.
    } catch (e) {
      // Có thể cập nhật lỗi nếu đăng xuất thất bại
      _errorMessage = 'Đăng xuất thất bại.';
      notifyListeners();
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _authRepository.resetPassword(email: email);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _handleAuthError(e.code);
      notifyListeners();
      throw e;
    }
  }

  Future<void> _executeAuthAction(Future<void> Function() action) async {
    _updateStatus(AuthStatus.loading);
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      // [REFINEMENT 3] Khi đăng nhập sai, trạng thái logic là unauthenticated với một thông báo lỗi.
      _updateStatus(AuthStatus.error, _handleAuthError(e.code));
    } catch (e) {
      _updateStatus(AuthStatus.error, 'Đã có lỗi xảy ra. Vui lòng thử lại.');
    }
  }

  String _handleAuthError(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      default:
        return 'Có lỗi xảy ra. Vui lòng thử lại sau.';
    }
  }

  void _updateStatus(AuthStatus status, [String message = '']) {
    _status = status;
    // Khi cập nhật status thành công (không phải lỗi), hãy xóa thông báo lỗi cũ.
    if (status != AuthStatus.error && status != AuthStatus.unauthenticated) {
      _errorMessage = '';
    } else {
      _errorMessage = message;
    }
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser != null) {
      try {
        final userModel = await _authRepository.getUserData(firebaseUser.uid);
        if (userModel != null) {
          _currentUser = userModel;
          notifyListeners();
        }
      } catch (e) {}
    }
  }

  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }
}
