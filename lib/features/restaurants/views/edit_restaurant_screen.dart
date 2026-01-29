// lib/features/restaurants/views/edit_restaurant_screen.dart
import 'dart:io';
import 'package:buaanyeuthuong/features/restaurants/viewmodels/edit_restaurant_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../authentication/repositories/auth_repository.dart';
import '../../authentication/viewmodels/auth_viewmodel.dart';
import '../../core/utils/debouncer.dart';
import '../models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/views/widgets/operating_hours_input.dart';
import 'package:buaanyeuthuong/features/restaurants/views/widgets/dynamic_address_picker.dart';

class EditRestaurantScreen extends StatefulWidget {
  final RestaurantModel initialRestaurant;

  const EditRestaurantScreen({Key? key, required this.initialRestaurant})
    : super(key: key);

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  final Map<String, TextEditingController> _hoursControllers = {};
  File? _selectedImage;
  String? _existingImageUrl;
  String ? _selectedProvince;
  String? _selectedDistrict;

  // [THÊM MỚI] State cho kiểm tra SĐT real-time
  final _phoneDebouncer = Debouncer(milliseconds: 500);
  bool _isCheckingPhone = false;
  bool _isPhoneUnique = true;
  String _phoneValidationMessage = '';

  @override
  void initState() {
    super.initState();
    // Điền sẵn thông tin từ quán ăn hiện tại
    final restaurant = widget.initialRestaurant;
    _nameController = TextEditingController(text: restaurant.name);
    _addressController = TextEditingController(text: restaurant.address);
    _phoneController = TextEditingController(text: restaurant.phoneNumber);
    _descriptionController = TextEditingController(
      text: restaurant.description,
    );
    _selectedProvince = restaurant.province;
    _selectedDistrict = restaurant.district;
    _existingImageUrl = restaurant.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _phoneDebouncer.dispose();
    _hoursControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 600,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Lấy ra AuthRepository để kiểm tra SĐT
    final authRepo = context.read<AuthRepository>();
    final viewModel = context.read<EditRestaurantViewModel>();

    final newPhoneNumber = _phoneController.text.trim();
    // Lấy SĐT gốc của người dùng, không phải của quán ăn
    final currentOwnerPhoneNumber = context
        .read<AuthViewModel>()
        .currentUser
        ?.phoneNumber;

    // Bật loading
    setState(() {
      /* Cần một biến isLoading riêng trong State này */
    });

    try {
      // --- LOGIC KIỂM TRA SĐT TRÙNG LẶP ---
      if (newPhoneNumber.isNotEmpty &&
          newPhoneNumber != currentOwnerPhoneNumber) {
        final bool exists = await authRepo.isPhoneNumberExists(newPhoneNumber);
        if (exists && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Số điện thoại này đã được sử dụng bởi một tài khoản khác.'),
              backgroundColor: Colors.red,
            ),
          );
          return; // Dừng lại
        }
      }
      // --- KẾT THÚC KIỂM TRA ---

      final operatingHours = <String, String>{};
      _hoursControllers.forEach((day, controller) {
        if (controller.text
            .trim()
            .isNotEmpty) {
          operatingHours[day] = controller.text.trim();
        }
      });

      final success = await viewModel.updateRestaurant(
        originalRestaurant: widget.initialRestaurant,
        name: _nameController.text.trim(),
        province: _selectedProvince!,
        district: _selectedDistrict!,
        address: _addressController.text.trim(),
        phoneNumber: newPhoneNumber,
        // Truyền SĐT mới
        description: _descriptionController.text.trim(),
        operatingHours: operatingHours,
        newImageFile: _selectedImage,
      );

      if (success && mounted) {
        // Quan trọng: Làm mới cả dữ liệu user và dữ liệu quán ăn
        await context.read<AuthViewModel>().refreshUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!')),
        );
        Navigator.of(context).pop();
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage ?? 'Có lỗi xảy ra.')),
        );
      }
    } finally {
      // Tắt loading
      setState(() {
        /* ... */
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin quán ăn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Widget hiển thị và chọn ảnh
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_existingImageUrl != null
                                      ? NetworkImage(_existingImageUrl!)
                                      : null)
                                  as ImageProvider?,
                        child:
                            _selectedImage == null && _existingImageUrl == null
                            ? const Icon(
                                Icons.business_rounded,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                            border: Border.all(width: 2, color: Colors.white),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(4.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Các TextFormField
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên quán ăn',
                ),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 20),
              // --- Khối chọn địa chỉ ---
              FormField<bool>(
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DynamicAddressPicker(
                        initialProvince: _selectedProvince,
                        initialDistrict: _selectedDistrict,
                        onAddressChanged: (province, district) {
                          setState(() {
                            _selectedProvince = province;
                            _selectedDistrict = district;
                          });
                          state.didChange(true);
                        },
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
                validator: (value) {
                  if (_selectedProvince == null || _selectedDistrict == null) {
                    return 'Vui lòng chọn đầy đủ địa chỉ.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể'),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại liên hệ',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isCheckingPhone
                      ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                      : (_phoneController.text.isNotEmpty && !_isPhoneUnique
                      ? const Icon(Icons.error, color: Colors.red)
                      : null),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  _formKey.currentState?.validate(); // Validate định dạng tức thì
                  _phoneDebouncer.run(() async {
                    final currentOwnerPhoneNumber = context.read<AuthViewModel>().currentUser?.phoneNumber;
                    // Chỉ kiểm tra API nếu SĐT hợp lệ và đã thay đổi
                    if (value.isNotEmpty && RegExp(r'^0[0-9]{9}$').hasMatch(value) && value != currentOwnerPhoneNumber) {
                      if (mounted) setState(() { _isCheckingPhone = true; });
                      final authRepo = context.read<AuthRepository>();
                      final exists = await authRepo.isPhoneNumberExists(value);
                      if (mounted) {
                        setState(() {
                          _isPhoneUnique = !exists;
                          _phoneValidationMessage = exists ? 'Số điện thoại này đã được sử dụng.' : '';
                          _isCheckingPhone = false;
                          _formKey.currentState?.validate();
                        });
                      }
                    } else {
                      if (mounted) setState(() { _isPhoneUnique = true; _phoneValidationMessage = ''; });
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (!RegExp(r'^0[0-9]{9}$').hasMatch(value)) return 'Số điện thoại không hợp lệ';
                  if (!_isPhoneUnique) return _phoneValidationMessage;
                  return null;
                },
              ),

              const SizedBox(height: 16),

              OperatingHoursInput(
                controllers: _hoursControllers,
                initialData: widget
                    .initialRestaurant
                    .operatingHours, // Truyền dữ liệu ban đầu
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn (tùy chọn)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Nút bấm
              Consumer<EditRestaurantViewModel>(
                builder: (context, viewModel, child) {
                  return viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text('Lưu thay đổi'),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
