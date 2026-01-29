// lib/features/meal_events/views/edit_meal_event_screen.dart
import 'package:buaanyeuthuong/features/meal_events/models/meal_event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:buaanyeuthuong/features/meal_events/viewmodels/edit_meal_event_viewmodel.dart';

class EditMealEventScreen extends StatefulWidget {
  final MealEventModel initialEvent;

  const EditMealEventScreen({Key? key, required this.initialEvent}) : super(key: key);

  @override
  State<EditMealEventScreen> createState() => _EditMealEventScreenState();
}

class _EditMealEventScreenState extends State<EditMealEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    _descriptionController = TextEditingController(text: event.description);
    _quantityController = TextEditingController(text: event.totalMealsOffered.toString());
    _startTimeController = TextEditingController(text: event.startTime);
    _endTimeController = TextEditingController(text: event.endTime);
    _selectedDate = event.eventDate.toDate();
    _startTime = _timeOfDayFromString(event.startTime);
    _endTime = _timeOfDayFromString(event.endTime);
  }

  TimeOfDay? _timeOfDayFromString(String timeString) {
    if (timeString.isEmpty) return null;
    try {
      final format = DateFormat.jm();
      final dt = format.parse(timeString);
      return TimeOfDay.fromDateTime(dt);
    } catch (e) {
      try {
        final parts = timeString.split(RegExp(r'[: ]'));
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e2) {
        return null;
      }
    }
  }

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
      firstDate: now.subtract(const Duration(days: 30)), // Cho phép sửa sự kiện trong quá khứ gần
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ ngày và giờ.')),
      );
      return;
    }

    final DateTime startDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _startTime!.hour, _startTime!.minute,
    );
    // [SỬA LỖI] Sử dụng _endTime ở đây
    DateTime endDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _endTime!.hour, _endTime!.minute,
    );



    // Chỉ xem xét trường hợp qua đêm nếu giờ bắt đầu >= 12:00 (buổi chiều/tối)
// VÀ giờ kết thúc < 12:00 (buổi sáng).
// Điều này ngăn trường hợp 1:00 AM -> 0:00 AM bị coi là qua đêm.
    bool isOvernight = _startTime!.hour >= 12 && _endTime!.hour < 12;

    if (isOvernight) {
      // Nếu đúng là qua đêm, cộng thêm 1 ngày vào ngày kết thúc
      endDateTime = endDateTime.add(const Duration(days: 1));
    }
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Giờ kết thúc phải sau giờ bắt đầu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (endDateTime.difference(startDateTime).inHours >= 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Một đợt phát ăn không thể kéo dài quá 24 giờ.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final viewModel = context.read<EditMealEventViewModel>();
    final success = await viewModel.updateMealEvent(
      originalEvent: widget.initialEvent,
      description: _descriptionController.text.trim(),
      totalMeals: int.parse(_quantityController.text.trim()),
      eventDate: _selectedDate!,
      startTime: _startTimeController.text,
      endTime: _endTimeController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công!')),
      );
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Có lỗi xảy ra.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa Đợt phát ăn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả bữa ăn'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Tổng số suất ăn'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập số lượng';
                  if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Số không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                // Dùng controller riêng cho ngày để nó không bị rebuild liên tục
                controller: TextEditingController(text: _selectedDate != null ? DateFormat.yMd().format(_selectedDate!) : ''),
                decoration: const InputDecoration(labelText: 'Ngày phát'),
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
              Consumer<EditMealEventViewModel>(
                builder: (context, viewModel, child) {
                  return viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _submitForm,
                    // [SỬA] Đổi text nút bấm
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