// lib/features/restaurants/views/edit_restaurant_screen.dart
import 'dart:io';
import 'package:buaanyeuthuong/features/restaurants/viewmodels/edit_restaurant_viewmodel.dart';
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

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;

  // Data
  final Map<String, TextEditingController> _hoursControllers = {};
  File? _selectedImage;
  String? _existingImageUrl;
  String? _selectedProvince;
  String? _selectedDistrict;

  // Validation State
  final _phoneDebouncer = Debouncer(milliseconds: 500);
  bool _isCheckingPhone = false;
  bool _isPhoneUnique = true;
  String _phoneValidationMessage = '';

  @override
  void initState() {
    super.initState();
    final r = widget.initialRestaurant;
    _nameController = TextEditingController(text: r.name);
    _addressController = TextEditingController(text: r.address);
    _phoneController = TextEditingController(text: r.phoneNumber);
    _descriptionController = TextEditingController(text: r.description);
    _selectedProvince = r.province;
    _selectedDistrict = r.district;
    _existingImageUrl = r.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _phoneDebouncer.dispose();
    _hoursControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Tăng chất lượng lên một chút
      maxWidth: 800,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authRepo = context.read<AuthRepository>();
    final viewModel = context.read<EditRestaurantViewModel>();
    final newPhoneNumber = _phoneController.text.trim();
    final currentOwnerPhone = context.read<AuthViewModel>().currentUser?.phoneNumber;

    // Loading indicator handled by Consumer in UI, but good to ensure logic safety

    try {
      // Validate Phone Unique
      if (newPhoneNumber.isNotEmpty && newPhoneNumber != currentOwnerPhone) {
        final exists = await authRepo.isPhoneNumberExists(newPhoneNumber);
        if (exists && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('SĐT này đã được sử dụng bởi tài khoản khác.'),
            backgroundColor: Colors.red,
          ));
          return;
        }
      }

      final hours = <String, String>{};
      _hoursControllers.forEach((d, c) {
        if (c.text.trim().isNotEmpty) hours[d] = c.text.trim();
      });

      final success = await viewModel.updateRestaurant(
        originalRestaurant: widget.initialRestaurant,
        name: _nameController.text.trim(),
        province: _selectedProvince!,
        district: _selectedDistrict!,
        address: _addressController.text.trim(),
        phoneNumber: newPhoneNumber,
        description: _descriptionController.text.trim(),
        operatingHours: hours,
        newImageFile: _selectedImage,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
        Navigator.of(context).pop();
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage ?? 'Có lỗi xảy ra.')));
      }
    } catch (e) {
      // Catch unexpected errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ẢNH ĐẠI DIỆN ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
                          image: _selectedImage != null
                              ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                              : (_existingImageUrl != null
                              ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                              : null),
                        ),
                        child: (_selectedImage == null && _existingImageUrl == null)
                            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.orange,
                          child: const Icon(Icons.edit, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- NHÓM 1: CƠ BẢN ---
              _buildSectionTitle('Thông tin chung'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Tên quán ăn',
                        icon: Icons.store,
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Hotline liên hệ',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        suffixIcon: _isCheckingPhone
                            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                            : (!_isPhoneUnique ? const Icon(Icons.error, color: Colors.red) : null),
                        onChanged: (val) {
                          _phoneDebouncer.run(() async {
                            // Logic check phone như cũ
                            if (val.isNotEmpty && val != widget.initialRestaurant.phoneNumber) {
                              setState(() => _isCheckingPhone = true);
                              final exists = await context.read<AuthRepository>().isPhoneNumberExists(val);
                              if (mounted) {
                                setState(() {
                                  _isPhoneUnique = !exists;
                                  _phoneValidationMessage = exists ? 'SĐT đã được sử dụng.' : '';
                                  _isCheckingPhone = false;
                                  _formKey.currentState?.validate();
                                });
                              }
                            }
                          });
                        },
                        validator: (val) {
                          if (val!.isEmpty) return 'Nhập SĐT';
                          if (!_isPhoneUnique) return _phoneValidationMessage;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Mô tả ngắn',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- NHÓM 2: ĐỊA CHỈ ---
              _buildSectionTitle('Địa chỉ'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FormField<bool>(
                        builder: (state) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DynamicAddressPicker(
                              initialProvince: _selectedProvince,
                              initialDistrict: _selectedDistrict,
                              onAddressChanged: (p, d) {
                                setState(() { _selectedProvince = p; _selectedDistrict = d; });
                                state.didChange(true);
                              },
                            ),
                            if (state.hasError)
                              Padding(padding: const EdgeInsets.only(left: 12, top: 8), child: Text(state.errorText!, style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
                          ],
                        ),
                        validator: (_) => (_selectedProvince == null || _selectedDistrict == null) ? 'Chọn đầy đủ Tỉnh/Huyện' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Số nhà, tên đường',
                        icon: Icons.location_on,
                        validator: (v) => v!.isEmpty ? 'Nhập địa chỉ chi tiết' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- NHÓM 3: GIỜ HOẠT ĐỘNG ---
              _buildSectionTitle('Giờ mở cửa'),
              OperatingHoursInput(
                controllers: _hoursControllers,
                initialData: widget.initialRestaurant.operatingHours,
              ),

              const SizedBox(height: 32),

              // BUTTON
              Consumer<EditRestaurantViewModel>(
                builder: (context, vm, child) {
                  return SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: vm.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: vm.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('LƯU THAY ĐỔI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}