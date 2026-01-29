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

    // --- LOGIC XÁC THỰC THỜI GIAN ĐÃ SỬA HOÀN CHỈNH ---
    final DateTime startDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _startTime!.hour, _startTime!.minute,
    );
    // [SỬA LỖI] Sử dụng _endTime ở đây
    DateTime endDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _endTime!.hour, _endTime!.minute,
    );

    // Logic kiểm tra qua đêm chặt chẽ
    bool isOvernight = _startTime!.hour >= 12 && _endTime!.hour < 12;
    if (isOvernight) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    // Kiểm tra cuối cùng
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Giờ kết thúc phải sau giờ bắt đầu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra thời lượng
    if (endDateTime.difference(startDateTime).inHours >= 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Một đợt phát ăn không thể kéo dài quá 24 giờ.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // --- KẾT THÚC LOGIC XÁC THỰC ---

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo đợt phát ăn thành công!')),
      );
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Đã có lỗi xảy ra.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đợt phát ăn mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả bữa ăn (VD: Cơm sườn)'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Tổng số suất ăn dự kiến'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập số lượng';
                  if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Số không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: TextEditingController(text: _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : ''),
                decoration: const InputDecoration(labelText: 'Ngày phát', hintText: 'Chọn ngày'),
                readOnly: true,
                onTap: _presentDatePicker,
                validator: (value) => value!.isEmpty ? 'Vui lòng chọn ngày' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(labelText: 'Giờ bắt đầu'),
                      readOnly: true,
                      onTap: () => _presentTimePicker(true),
                      validator: (value) => value!.isEmpty ? 'Vui lòng chọn giờ' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(labelText: 'Giờ kết thúc'),
                      readOnly: true,
                      onTap: () => _presentTimePicker(false),
                      validator: (value) => value!.isEmpty ? 'Vui lòng chọn giờ' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Consumer<CreateMealEventViewModel>(
                builder: (context, viewModel, child) {
                  return viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Tạo đợt phát ăn'),
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