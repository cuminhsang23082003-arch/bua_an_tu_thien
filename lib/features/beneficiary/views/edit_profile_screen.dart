// lib/features/beneficiary/views/edit_profile_screen.dart
import 'package:buaanyeuthuong/features/authentication/repositories/auth_repository.dart';
import 'package:buaanyeuthuong/features/authentication/models/user_model.dart';
import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/restaurants/views/widgets/dynamic_address_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _selectedProvince;
  String? _selectedDistrict;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _displayNameController = TextEditingController(text: user.displayName);
    _phoneController = TextEditingController(text: user.phoneNumber ?? '');
    _addressController = TextEditingController(text: user.address ?? '');
    _selectedProvince = user.province;
    _selectedDistrict = user.district;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // 1. Kiểm tra validation cơ bản của Form
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    final authRepo = context.read<AuthRepository>();
    final newPhoneNumber = _phoneController.text.trim();
    final currentPhoneNumber = widget.user.phoneNumber;

    try {
      // 2. [LOGIC KIỂM TRA SĐT] Chỉ kiểm tra nếu SĐT mới khác SĐT cũ VÀ không rỗng
      if (newPhoneNumber.isNotEmpty && newPhoneNumber != currentPhoneNumber) {
        final bool exists = await authRepo.isPhoneNumberExists(newPhoneNumber);
        if (exists && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Số điện thoại này đã được sử dụng bởi một tài khoản khác.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { _isLoading = false; });
          return; // Dừng lại nếu SĐT đã tồn tại
        }
      }

      // 3. Nếu SĐT hợp lệ, tiếp tục cập nhật tất cả dữ liệu
      await authRepo.updateUserData(
        uid: widget.user.uid,
        displayName: _displayNameController.text.trim(),
        phoneNumber: newPhoneNumber,
        province: _selectedProvince,
        district: _selectedDistrict,
        address: _addressController.text.trim(),
      );

      // 4. Cập nhật thành công
      if (mounted) {
        await context.read<AuthViewModel>().refreshUserData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cập nhật thất bại: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _displayNameController,
                label: 'Tên hiển thị',
                validator: (value) => value!.isEmpty ? 'Tên không được để trống' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  // SĐT không bắt buộc, nhưng nếu nhập thì phải đúng định dạng
                  if (value != null && value.isNotEmpty && !RegExp(r'^0[0-9]{9}$').hasMatch(value)) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              DynamicAddressPicker(
                initialProvince: widget.user.province,
                initialDistrict: widget.user.district,
                onAddressChanged: (province, district) {
                  setState(() {
                    _selectedProvince = province;
                    _selectedDistrict = district;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Địa chỉ chi tiết (Số nhà, đường)',
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper để code gọn hơn
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}