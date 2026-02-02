// lib/features/authentication/views/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để dùng inputFormatters
import 'package:provider/provider.dart';

// Import Debouncer & Services
import '../../core/utils/debouncer.dart';
import '../../core/services/snackbar_service.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // --- [LOGIC KIỂM TRA SĐT REAL-TIME] ---
  final _phoneDebouncer = Debouncer(milliseconds: 500);
  bool _isCheckingPhone = false;
  bool _isPhoneUnique = true;
  String _phoneValidationMessage = '';
  // -------------------------------------

  // State nội bộ
  bool _isObscure = true;
  UserRole _selectedRole = UserRole.beneficiary;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneDebouncer.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (_isCheckingPhone) return;
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();

    await authViewModel.submitAuth(
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      role: _selectedRole,
    );

    if (authViewModel.status == AuthStatus.error && mounted) {
      SnackBarService.showError(authViewModel.errorMessage);
    }
  }

  void _onPhoneChanged(String value, bool isLoginMode) {
    if (isLoginMode) return;

    if (_phoneValidationMessage.isNotEmpty) {
      setState(() {
        _isPhoneUnique = true;
        _phoneValidationMessage = '';
      });
    }

    _phoneDebouncer.run(() async {
      if (value.isNotEmpty && RegExp(r'^0[0-9]{9}$').hasMatch(value)) {
        if (mounted) {
          setState(() {
            _isCheckingPhone = true;
          });
        }

        final authRepo = context.read<AuthRepository>();
        final exists = await authRepo.isPhoneNumberExists(value);

        if (mounted) {
          setState(() {
            _isCheckingPhone = false;
            _isPhoneUnique = !exists;
            _phoneValidationMessage = exists ? 'Số điện thoại này đã được sử dụng.' : '';
            _formKey.currentState?.validate();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final isLogin = authViewModel.isLoginMode;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- 1. LOGO ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, size: 48, color: Colors.orange),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bữa Ăn Yêu Thương',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLogin ? 'Đăng nhập để tiếp tục' : 'Tạo tài khoản mới',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 30),

                      // --- 2. FORM NHẬP LIỆU ---

                      if (!isLogin) ...[
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _buildInputDecoration(
                            label: 'Họ và tên',
                            icon: Icons.person_outline,
                          ),
                          validator: (val) {
                            if (!isLogin && (val == null || val.trim().length < 2)) {
                              return 'Vui lòng nhập họ tên đầy đủ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        onChanged: (val) => _onPhoneChanged(val, isLogin),
                        decoration: _buildInputDecoration(
                          label: 'Số điện thoại',
                          icon: Icons.phone_android_outlined,
                          hint: 'Ví dụ: 0912345678',
                        ).copyWith(
                          suffixIcon: _isCheckingPhone
                              ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2)
                            ),
                          )
                              : (!isLogin && !_isPhoneUnique)
                              ? const Icon(Icons.error, color: Colors.red)
                              : null,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Vui lòng nhập SĐT';
                          if (val.length < 9) return 'Số điện thoại không hợp lệ';
                          if (!isLogin && !_isPhoneUnique) {
                            return _phoneValidationMessage;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: _buildInputDecoration(
                          label: 'Mật khẩu',
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _isObscure = !_isObscure),
                          ),
                          helperText: !isLogin ? 'Tối thiểu 6 ký tự' : null,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (!isLogin && val.length < 6) return 'Mật khẩu quá ngắn';
                          return null;
                        },
                      ),

                      if (!isLogin) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: Colors.orange,
                            title: const Text(
                              'Đăng ký với tư cách là chủ quán ăn',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Tick vào đây nếu bạn muốn tạo quán và trao tặng suất ăn.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            value: _selectedRole == UserRole.restaurantOwner,
                            onChanged: (val) {
                              setState(() {
                                _selectedRole = (val == true)
                                    ? UserRole.restaurantOwner
                                    : UserRole.beneficiary;
                              });
                            },
                          ),
                        ),
                      ],

                      if (authViewModel.status == AuthStatus.error &&
                          authViewModel.errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            authViewModel.errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // --- 4. NÚT BẤM CHÍNH ---
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (authViewModel.status == AuthStatus.loading || _isCheckingPhone)
                              ? null
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: authViewModel.status == AuthStatus.loading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Text(
                            isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ NGAY',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- 5. CHUYỂN ĐỔI LOGIN / REGISTER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? ',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                          ),
                          const SizedBox(width: 8), // Khoảng cách giữa chữ và nút

                          // [NÚT CHUYỂN ĐỔI CÓ VIỀN]
                          GestureDetector(
                            onTap: () {
                              _formKey.currentState?.reset();
                              setState(() {
                                _isPhoneUnique = true;
                                _phoneValidationMessage = '';
                              });
                              authViewModel.toggleAuthMode();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFFF6B6B), width: 1.5),
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.white,
                              ),
                              child: Text(
                                isLogin ? 'Đăng ký' : 'Đăng nhập',
                                style: const TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
    );
  }
}