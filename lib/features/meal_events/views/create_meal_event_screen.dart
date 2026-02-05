// lib/features/meal_events/views/create_meal_event_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../viewmodels/create_meal_event_viewmodel.dart';

class CreateMealEventScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const CreateMealEventScreen({Key? key, required this.restaurant}) : super(key: key);

  @override
  State<CreateMealEventScreen> createState() => _CreateMealEventScreenState();
}

class _CreateMealEventScreenState extends State<CreateMealEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _presentTimePicker(bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
          _startTimeController.text = pickedTime.format(context);
        } else {
          _endTime = pickedTime;
          _endTimeController.text = pickedTime.format(context);
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ ngày và giờ.')),
      );
      return;
    }

    // --- LOGIC XÁC THỰC GIỮ NGUYÊN ---
    final DateTime startDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _startTime!.hour, _startTime!.minute,
    );
    DateTime endDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _endTime!.hour, _endTime!.minute,
    );

    bool isOvernight = _startTime!.hour >= 12 && _endTime!.hour < 12;
    if (isOvernight) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Giờ kết thúc phải sau giờ bắt đầu.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (endDateTime.difference(startDateTime).inHours >= 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Một đợt phát ăn không thể kéo dài quá 24 giờ.'), backgroundColor: Colors.red),
      );
      return;
    }
    // --- KẾT THÚC LOGIC ---

    final viewModel = context.read<CreateMealEventViewModel>();
    final success = await viewModel.createMealEvent(
      restaurant: widget.restaurant,
      description: _descriptionController.text.trim(),
      totalMeals: int.parse(_quantityController.text.trim()),
      eventDate: _selectedDate!,
      startTime: _startTimeController.text,
      endTime: _endTimeController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo đợt phát ăn thành công!')));
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage ?? 'Đã có lỗi xảy ra.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format hiển thị ngày giờ cho đẹp
    final dateDisplay = _selectedDate != null
        ? DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate!)
        : 'Chọn ngày tổ chức';

    final startTimeDisplay = _startTime != null
        ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    final endTimeDisplay = _endTime != null
        ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Màu nền nhẹ nhàng
      appBar: AppBar(
        title: const Text('Tạo đợt phát ăn'),
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
              // --- NHÓM 1: THÔNG TIN CƠ BẢN ---
              _buildSectionTitle('Thông tin suất ăn'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Tên món / Mô tả',
                          hintText: 'VD: Cơm sườn, Bún bò...',
                          prefixIcon: const Icon(Icons.restaurant_menu, color: Colors.orange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) => value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Số lượng suất',
                          suffixText: 'suất',
                          prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Colors.orange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập số lượng';
                          if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Số không hợp lệ';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- NHÓM 2: THỜI GIAN ---
              _buildSectionTitle('Thời gian tổ chức'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Widget chọn ngày tùy chỉnh
                      InkWell(
                        onTap: _presentDatePicker,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  dateDisplay,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedDate != null ? Colors.black87 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Row chứa 2 ô chọn giờ
                      Row(
                        children: [
                          Expanded(
                            child: _buildCustomTimePicker(
                              label: 'Bắt đầu',
                              timeDisplay: startTimeDisplay,
                              isSelected: _startTime != null,
                              onTap: () => _presentTimePicker(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCustomTimePicker(
                              label: 'Kết thúc',
                              timeDisplay: endTimeDisplay,
                              isSelected: _endTime != null,
                              onTap: () => _presentTimePicker(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- NÚT SUBMIT ---
              Consumer<CreateMealEventViewModel>(
                builder: (context, viewModel, child) {
                  return SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'XÁC NHẬN TẠO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget tiêu đề section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
      ),
    );
  }

  // Widget chọn giờ tùy chỉnh (thay thế TextFormField)
  Widget _buildCustomTimePicker({
    required String label,
    required String timeDisplay,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              timeDisplay,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}