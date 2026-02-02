// lib/features/restaurants/views/create_restaurant_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Models & ViewModels
import '../../authentication/models/user_model.dart';
import '../viewmodels/create_restaurant_viewmodel.dart';

// Widgets
import 'widgets/operating_hours_input.dart';
import 'widgets/dynamic_address_picker.dart';

class CreateRestaurantScreen extends StatefulWidget {
  final UserModel owner;
  const CreateRestaurantScreen({Key? key, required this.owner}) : super(key: key);

  @override
  State<CreateRestaurantScreen> createState() => _CreateRestaurantScreenState();
}

class _CreateRestaurantScreenState extends State<CreateRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  late TextEditingController _phoneController;

  // Dữ liệu Map Controller cho giờ mở cửa
  final Map<String, TextEditingController> _hoursControllers = {};

  // State dữ liệu
  File? _selectedImage;
  String? _selectedProvince;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    // Tự động điền SĐT từ tài khoản User
    _phoneController = TextEditingController(text: widget.owner.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    // Dispose các controller trong Map
    _hoursControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Giảm chất lượng chút để upload nhanh hơn
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    // 1. Validate Form cơ bản
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Validate Địa chỉ
    if (_selectedProvince == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Tỉnh/Thành phố và Quận/Huyện.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 3. Validate Ảnh
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh đại diện cho quán (Ảnh biển hiệu, mặt tiền...)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final viewModel = context.read<CreateRestaurantViewModel>();

    // 4. Thu thập dữ liệu giờ hoạt động
    final operatingHours = <String, String>{};
    _hoursControllers.forEach((day, controller) {
      if (controller.text.trim().isNotEmpty) {
        operatingHours[day] = controller.text.trim();
      }
    });

    // 5. Gọi ViewModel
    final success = await viewModel.createRestaurant(
      name: _nameController.text.trim(),
      province: _selectedProvince!,
      district: _selectedDistrict!,
      address: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      description: _descriptionController.text.trim(),
      owner: widget.owner,
      operatingHours: operatingHours,
      imageFile: _selectedImage,
    );

    // Xử lý lỗi nếu có (Nếu thành công, RestaurantOwnerGate sẽ tự chuyển màn hình)
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Đã có lỗi xảy ra.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Màu nền nhẹ nhàng
      appBar: AppBar(
        title: const Text('Đăng ký Hồ sơ Quán ăn'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIntroCard(),
              const SizedBox(height: 16),

              _buildBasicInfoSection(),
              const SizedBox(height: 16),

              _buildLocationSection(),
              const SizedBox(height: 16),

              _buildImageSection(),
              const SizedBox(height: 16),

              _buildOperatingHoursSection(),
              const SizedBox(height: 32),

              _buildSubmitButton(),
              const SizedBox(height: 40), // Khoảng trống dưới cùng
            ],
          ),
        ),
      ),
    );
  }

  // --- CÁC WIDGET CON (Để code gọn gàng hơn) ---

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Thông tin quán sẽ được Admin kiểm duyệt trước khi hiển thị công khai.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Thông tin cơ bản', Icons.storefront),
        _buildCard(
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Tên quán ăn', Icons.store),
                validator: (val) => val!.isEmpty ? 'Vui lòng nhập tên quán' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Số điện thoại liên hệ', Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Vui lòng nhập SĐT' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Mô tả ngắn', Icons.description).copyWith(
                    alignLabelWithHint: true,
                    hintText: 'VD: Quán cơm bình dân, chuyên phục vụ cơm tấm...'
                ),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Hãy viết mô tả ngắn' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Địa chỉ quán', Icons.location_on),
        _buildCard(
          child: Column(
            children: [
              FormField<bool>(
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DynamicAddressPicker(
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
                          child: Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  );
                },
                validator: (_) => (_selectedProvince == null || _selectedDistrict == null)
                    ? 'Vui lòng chọn địa chỉ.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Số nhà, tên đường', Icons.home),
                validator: (val) => val!.isEmpty ? 'Vui lòng nhập địa chỉ chi tiết' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hình ảnh quán', Icons.image),
        _buildCard(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Chạm để tải ảnh lên", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                      : null,
                ),
              ),
              if (_selectedImage != null)
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.edit),
                  label: const Text("Thay đổi ảnh"),
                )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Thời gian hoạt động', Icons.access_time),
        // OperatingHoursInput đã tự có Card bên trong rồi nên không cần bọc nữa
        OperatingHoursInput(controllers: _hoursControllers),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<CreateRestaurantViewModel>(
      builder: (context, viewModel, child) {
        return SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: viewModel.isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: viewModel.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              'Gửi hồ sơ xét duyệt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}