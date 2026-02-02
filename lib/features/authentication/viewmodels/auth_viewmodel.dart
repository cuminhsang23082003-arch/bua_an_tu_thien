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
  error,
}

class AuthViewModel with ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';
  UserModel? _currentUser;

  // [MỚI] Biến để xác định đang ở chế độ Đăng nhập hay Đăng ký
  bool _isLoginMode = true;

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoginMode => _isLoginMode; // Getter cho UI

  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // [MỚI] Hàm chuyển đổi qua lại giữa Đăng nhập và Đăng ký
  void toggleAuthMode() {
    _isLoginMode = !_isLoginMode;
    _errorMessage = ''; // Xóa lỗi cũ khi chuyển tab
    notifyListeners();
  }

  // [MỚI] Hàm tiện ích: Chuyển SĐT thành Email giả định
  // Trick: Firebase cần email, ta dùng sdt + đuôi domain của app
  String _convertToEmail(String phone) {
    final cleanPhone = phone.trim().replaceAll(' ', '');
    return '$cleanPhone@buaanyeuthuong.vn';
  }

  void _listenToAuthChanges() {
    if (_status == AuthStatus.initial) {
      _updateStatus(AuthStatus.loading);
    }

    _authSubscription = _authRepository.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _updateStatus(AuthStatus.unauthenticated);
        return;
      }
      try {
        final userModel = await _authRepository.getUserData(firebaseUser.uid);
        if (userModel != null) {
          _currentUser = userModel;
          _updateStatus(AuthStatus.authenticated);
        } else {
          // Trường hợp hiếm: Có Auth nhưng mất data Firestore -> Đăng xuất
          await _authRepository.signOut();
          _updateStatus(
            AuthStatus.error,
            'Dữ liệu người dùng không đồng bộ. Vui lòng thử lại.',
          );
        }
      } catch (e) {
        _currentUser = null;
        _updateStatus(AuthStatus.error, 'Lỗi khi lấy dữ liệu người dùng.');
      }
    });
  }

  // [MỚI] Hàm xử lý chính cho cả Đăng nhập và Đăng ký
  // View chỉ cần gọi hàm này khi nhấn nút "Tiếp tục" / "Xác nhận"
  Future<void> submitAuth({
    required String phoneNumber,
    required String password,
    String? name, // Chỉ cần khi đăng ký
    UserRole role = UserRole.beneficiary, // Mặc định là người nhận
  }) async {
    _updateStatus(AuthStatus.loading);

    try {
      final email = _convertToEmail(phoneNumber);

      if (_isLoginMode) {
        // --- LOGIC ĐĂNG NHẬP ---
        await _authRepository.signIn(email: email, password: password);
        // Listener sẽ tự chuyển state -> authenticated
      } else {
        // --- LOGIC ĐĂNG KÝ ---

        // 1. Kiểm tra SĐT trong Firestore (Optional nhưng nên giữ để chắc chắn)
        // Lưu ý: Firebase Auth check email trùng cũng tương đương check sdt trùng
        // nhưng check Firestore giúp đảm bảo logic nghiệp vụ.
        if (phoneNumber.isNotEmpty) {
          final bool phoneExists = await _authRepository.isPhoneNumberExists(phoneNumber);
          if (phoneExists) {
            throw Exception("Số điện thoại này đã được sử dụng.");
          }
        }

        // 2. Tạo tài khoản Auth
        final userCredential = await _authRepository.signUp(
          email: email,
          password: password,
        );

        // 3. Lưu dữ liệu vào Firestore
        final newUser = UserModel.fromFirebaseUser(
          userCredential.user!,
          role,
          displayName: name ?? 'Người dùng', // Tên mặc định nếu không nhập
          phoneNumber: phoneNumber, // Lưu số điện thoại thực
        );
        await _authRepository.saveUserDataToFirestore(newUser);
      }
    } on FirebaseAuthException catch (e) {
      _updateStatus(AuthStatus.error, _handleAuthError(e.code));
    } catch (e) {
      // Làm sạch thông báo lỗi (bỏ chữ Exception: )
      _updateStatus(AuthStatus.error, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      _errorMessage = 'Đăng xuất thất bại.';
      notifyListeners();
    }
  }

  // Reset mật khẩu (vẫn cần logic email, nhưng ở đây ta truyền email giả vào)
  // Lưu ý: Tính năng này sẽ gửi email về cái địa chỉ giả (@buaanyeuthuong.vn)
  // nên thực tế người dùng SĐT sẽ KHÔNG nhận được mail reset.
  // Với đối tượng lao động, nên khuyên họ liên hệ admin hoặc tạo tài khoản mới nếu quên.
  Future<void> resetPassword({required String phoneNumber}) async {
    try {
      final email = _convertToEmail(phoneNumber);
      await _authRepository.resetPassword(email: email);
      // Thông báo UI (thực tế email này không tồn tại nên họ không nhận được đâu)
      // Đây là hạn chế của việc dùng trick SĐT -> Email giả.
    } on FirebaseAuthException catch (e) {
      _errorMessage = _handleAuthError(e.code);
      notifyListeners();
      throw e;
    }
  }

  // Hàm xử lý lỗi, đã Việt hóa cho phù hợp ngữ cảnh "Số điện thoại"
  String _handleAuthError(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Số điện thoại này đã được đăng ký.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
      // Gộp chung lỗi để bảo mật và tránh bối rối
        return 'Sai số điện thoại hoặc mật khẩu.';
      case 'invalid-email':
        return 'Số điện thoại không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (cần ít nhất 6 ký tự).';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      default:
        return 'Đã có lỗi xảy ra ($errorCode). Vui lòng thử lại.';
    }
  }

  void _updateStatus(AuthStatus status, [String message = '']) {
    _status = status;
    if (status != AuthStatus.error && status != AuthStatus.unauthenticated) {
      _errorMessage = '';
    } else {
      _errorMessage = message;
    }
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }
}