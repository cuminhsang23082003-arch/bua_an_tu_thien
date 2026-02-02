// lib/features/restaurants/views/widgets/operating_hours_input.dart
import 'package:flutter/material.dart';

class OperatingHoursInput extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
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
  final List<String> days = [
    'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
  ];

  TimeOfDay defaultOpen = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay defaultClose = const TimeOfDay(hour: 22, minute: 0);

  @override
  void initState() {
    super.initState();
    for (var day in days) {
      if (!widget.controllers.containsKey(day)) {
        widget.controllers[day] = TextEditingController(
          text: widget.initialData?[day] ?? '08:00 - 22:00',
        );
      }
    }
  }

  // --- LOGIC XỬ LÝ ---

  Future<void> _selectTime(String day, bool isStartTime) async {
    final controller = widget.controllers[day]!;
    final currentText = controller.text;

    TimeOfDay initialTime = isStartTime ? defaultOpen : defaultClose;

    // Parse giờ hiện tại từ text để hiển thị lên đồng hồ
    if (currentText.contains('-') && !currentText.contains('Đóng cửa')) {
      final parts = currentText.split(' - ');
      if (parts.length == 2) {
        initialTime = _parseTime(isStartTime ? parts[0] : parts[1]);
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        String currentStart = currentText.contains('-') ? currentText.split(' - ')[0] : _formatTime(defaultOpen);
        String currentEnd = currentText.contains('-') ? currentText.split(' - ')[1] : _formatTime(defaultClose);

        String newStart = isStartTime ? _formatTime(picked) : currentStart;
        String newEnd = isStartTime ? currentEnd : _formatTime(picked);

        // Logic: Nếu giờ Mở > Giờ Đóng -> Tự động đẩy giờ Đóng lên bằng giờ Mở
        if (isStartTime) {
          double startVal = _timeToDouble(picked);
          double endVal = _timeToDouble(_parseTime(newEnd));
          if (endVal < startVal) newEnd = newStart;
        }

        controller.text = '$newStart - $newEnd';
      });
    }
  }

  void _toggleClose(String day, bool? isClosed) {
    setState(() {
      if (isClosed == true) {
        widget.controllers[day]!.text = 'Đóng cửa';
      } else {
        widget.controllers[day]!.text =
        '${_formatTime(defaultOpen)} - ${_formatTime(defaultClose)}';
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.trim().split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  double _timeToDouble(TimeOfDay myTime) => myTime.hour + myTime.minute / 60.0;

  // --- GIAO DIỆN (UI) ---

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề đã được CreateRestaurantScreen xử lý, nhưng giữ đây cũng không sao
        // Nếu muốn bỏ tiêu đề trùng lặp thì xóa Padding này đi
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300)
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Column(
              children: days.map((day) {
                final controller = widget.controllers[day]!;
                final isClosed = controller.text == 'Đóng cửa';

                // Tách chuỗi để lấy giờ hiển thị lên nút
                String startDisplay = '--:--';
                String endDisplay = '--:--';
                if (!isClosed && controller.text.contains('-')) {
                  final parts = controller.text.split(' - ');
                  if (parts.length == 2) {
                    startDisplay = parts[0];
                    endDisplay = parts[1];
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      // 1. Tên ngày
                      SizedBox(
                        width: 70,
                        child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),

                      // 2. Checkbox Nghỉ
                      SizedBox(
                        width: 30,
                        child: Checkbox(
                          value: isClosed,
                          activeColor: Colors.red,
                          onChanged: (val) => _toggleClose(day, val),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const Text("Nghỉ", style: TextStyle(fontSize: 12, color: Colors.grey)),

                      const SizedBox(width: 12),

                      // 3. Khu vực chọn giờ (Ẩn hiện tùy theo checkbox)
                      if (!isClosed) ...[
                        _buildTimeChip(context, startDisplay, () => _selectTime(day, true)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                        ),
                        _buildTimeChip(context, endDisplay, () => _selectTime(day, false)),
                      ] else ...[
                        // Hiển thị chữ "Không hoạt động" khi chọn nghỉ
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Text(
                              "Không hoạt động",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade300, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      ]
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

  // Widget con hiển thị ô giờ (Click vào để mở TimePicker)
  Widget _buildTimeChip(BuildContext context, String time, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }
}