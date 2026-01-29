// lib/features/restaurants/views/widgets/operating_hours_input.dart
import 'package:flutter/material.dart';

class OperatingHoursInput extends StatefulWidget {
  // Map chứa các controller, giúp ta lấy dữ liệu từ bên ngoài
  final Map<String, TextEditingController> controllers;
  // Dữ liệu ban đầu (dùng cho màn hình Edit)
  final Map<String, String>? initialData;

  const OperatingHoursInput({
    Key? key,
    required this.controllers,
    this.initialData,
  }) : super(key: key);

  @override
  State<OperatingHoursInput> createState() => _OperatingHoursInputState();
}

class _OperatingHoursInputState extends State<OperatingHoursInput> {
  // Danh sách các ngày trong tuần (key tiếng Anh để lưu vào DB)
  final List<String> days = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];

  @override
  void initState() {
    super.initState();
    // Khởi tạo các controller và điền dữ liệu ban đầu (nếu có)
    for (var day in days) {
      widget.controllers[day] = TextEditingController(
        text: widget.initialData?[day] ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            'Giờ hoạt động',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        // Tạo một Card để nhóm các trường nhập liệu lại
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: days.map((day) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Hiển thị tên ngày (tiếng Việt)
                      SizedBox(
                        width: 80, // Độ rộng cố định để căn chỉnh
                        child: Text(day),
                      ),
                      const SizedBox(width: 16),
                      // Trường nhập liệu cho giờ
                      Expanded(
                        child: TextFormField(
                          controller: widget.controllers[day],
                          decoration: InputDecoration(
                            hintText: 'VD: 9:00 - 17:00 hoặc đóng cửa',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // Không cần validator ở đây, vì có thể để trống
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}