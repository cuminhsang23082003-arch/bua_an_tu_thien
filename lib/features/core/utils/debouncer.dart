// lib/core/utils/debouncer.dart
import 'dart:async';
import 'dart:ui';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    // Nếu có một timer đang chạy, hủy nó đi
    _timer?.cancel();
    // Bắt đầu một timer mới. Sau khi hết thời gian, nó sẽ chạy action.
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}