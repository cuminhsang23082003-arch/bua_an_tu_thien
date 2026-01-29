// lib/features/restaurants/views/create_restaurant_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:buaanyeuthuong/features/restaurants/views/widgets/operating_hours_input.dart';
import 'package:buaanyeuthuong/features/restaurants/viewmodels/create_restaurant_viewmodel.dart';
import 'package:buaanyeuthuong/features/restaurants/views/widgets/dynamic_address_picker.dart';

class CreateRestaurantScreen extends StatefulWidget {
  final UserModel owner;
  const CreateRestaurantScreen({Key? key, required this.owner}) : super(key: key);

  @override
  State<CreateRestaurantScreen> createState() => _CreateRestaurantScreenState();
}

class _CreateRestaurantScreenState extends State<CreateRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  String? _selectedProvince;
  String? _selectedDistrict;
  late TextEditingController _phoneController;
  final Map <String, TextEditingController> _hoursControllers ={};

  @override
  void initState() {
    super.initState();
    // 2. Tự động điền SĐT từ widget.owner
    _phoneController = TextEditingController(text: widget.owner.phoneNumber ?? '');
    // ... khởi tạo các controller khác
  }


  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _hoursControllers.forEach((_, controller) => controller.dispose());

    super.dispose();
  }



  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =  await picker.pickImage(
        source: ImageSource.gallery,
    imageQuality: 50,
    maxWidth: 600,
    );

    if(pickedFile != null){
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if(_selectedProvince == null || _selectedDistrict == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ Tỉnh/Thành phố và Quận/Huyện.')),
      );
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một ảnh đại diện cho quán.')),
      );
      return;
    }

    final viewModel = context.read<CreateRestaurantViewModel>();
    final owner = widget.owner;

    // Lấy dữ liệu giờ từ controllers
    final operatingHours = <String, String>{};
    _hoursControllers.forEach((day, controller) {
      if (controller.text.trim().isNotEmpty) {
        operatingHours[day] = controller.text.trim();
      }
    });

    final success = await viewModel.createRestaurant(
      name: _nameController.text.trim(),
      province: _selectedProvince!,
      district: _selectedDistrict!,
      address: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      description: _descriptionController.text.trim(),
      owner: owner,
      operatingHours: operatingHours,
      imageFile: _selectedImage,
    );

    // Sau khi tạo thành công, Gate sẽ tự động chuyển màn hình.
    // Chúng ta không cần làm gì ở đây.
    // Nếu thất bại, ViewModel đã có errorMessage.
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Đã có lỗi xảy ra.')),
      );
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập thông tin quán ăn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chào mừng! Hãy bắt đầu bằng cách cung cấp thông tin về quán ăn của bạn.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên quán ăn'),
                validator: (value) =>
                value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 24),
              //Widget chọn địa chỉ động
              FormField<bool>(
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DynamicAddressPicker(
                          onAddressChanged: (province, district){
                            setState(() {
                              _selectedProvince = province;
                              _selectedDistrict = district;
                            });
                            // Báo cho FormField biết là giá trị đã thay đổi để nó tự validate lại
                            state.didChange(true);
                          },
                      ),
                      // Hiển thị lỗi nếu có
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
                decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết (Số nhà, tên đường...)'),
                validator: (value) =>
                value!.isEmpty ? 'Vui lòng nhập địa chỉ chi tiết' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại liên hệ'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                value!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn',hintText: 'Hãy mô tả ngắn về quán ăn của bạn (nếu có)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                    child: _selectedImage == null
                        ? const Icon(Icons.camera_alt, size: 50, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text("Hãy cung cấp ảnh về quán ăn của bạn")),
              OperatingHoursInput(controllers: _hoursControllers),

              const SizedBox(height: 32),
              Consumer<CreateRestaurantViewModel>(
                builder: (context, viewModel, child) {
                  return viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Tạo và Tiếp tục'),
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