// lib/features/meal_events/views/meal_events_list_screen.dart
import 'package:buaanyeuthuong/features/meal_events/models/meal_event_model.dart';
import 'package:buaanyeuthuong/features/meal_events/repositories/meal_event_repository.dart';
import 'package:buaanyeuthuong/features/meal_events/views/edit_meal_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MealEventsListScreen extends StatelessWidget {
  final String restaurantId;

  const MealEventsListScreen({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mealEventRepo = context.read<MealEventRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý các đợt phát suất ăn')),
      body: StreamBuilder<List<MealEventModel>>(
        stream: mealEventRepo.getMealEventsForRestaurantStream(restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text('Chưa có đợt phát ăn nào được tạo.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            // Thêm padding cho ListView
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventListItem(context, event, mealEventRepo);
            },
          );
        },
      ),
    );
  }

  // Widget cho một item trong danh sách - ĐÃ SỬA LẠI HOÀN CHỈNH
  Widget _buildEventListItem(
    BuildContext context,
    MealEventModel event,
    MealEventRepository repo,
  ) {
    final MealEventStatus currentStatus = event.effectiveStatus;
    final bool isActionable = currentStatus == MealEventStatus.scheduled;


    Color cardColor;
    switch (currentStatus) {
      case MealEventStatus.ongoing:
        cardColor = Colors.green.shade50;
        break;
      case MealEventStatus.cancelled:
      case MealEventStatus.completed:
        cardColor = Colors.grey.shade200;
        break;
      default: // scheduled
        cardColor = Colors.white;
        break;
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Column(
        children: [
          ListTile(
            title: Text(
              event.description,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            // [SỬA] Subtitle là một Column chứa các thông tin chi tiết
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    'Ngày: ${DateFormat('dd/MM/yyyy').format(event.eventDate.toDate())}',
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.access_time_outlined,
                    'Thời gian: ${event.startTime} - ${event.endTime}',
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.restaurant_menu_outlined,
                    'Còn lại: ${event.remainingMeals}/${event.totalMealsOffered} suất',
                  ),
                ],
              ),
            ),
            // [SỬA] Trailing là Chip trạng thái tiếng Việt
            trailing: Chip(
              label: Text(
                event.vietnameseStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _getStatusColor(currentStatus),
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          ),
          // if (isActionable)
            // Hàng chứa các nút hành động
          if(isActionable)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Sửa'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EditMealEventScreen(initialEvent: event),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Vô hiệu hóa',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () =>
                        _showDisableConfirmDialog(context, event, repo),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Widget con để hiển thị một dòng thông tin trong subtitle
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  // Tách logic dialog ra một hàm riêng cho gọn
  Future<void> _showDisableConfirmDialog(
    BuildContext context,
    MealEventModel event,
    MealEventRepository repo,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận vô hiệu hóa'),
        content: const Text(
          'Bạn có chắc chắn muốn vô hiệu hóa đợt phát ăn này không? Nó sẽ không hiển thị cho người nhận nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Vô hiệu hóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Gọi hàm cập nhật trạng thái sang 'cancelled'
        await repo.updateMealEventStatus(event.id, MealEventStatus.cancelled);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã vô hiệu hóa đợt phát ăn.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // Hàm helper để chọn màu cho Chip trạng thái
  Color _getStatusColor(MealEventStatus status) {
    switch (status) {
      case MealEventStatus.scheduled:
        return Colors.blue.shade400;
      case MealEventStatus.ongoing:
        return Colors.green.shade400;
      case MealEventStatus.completed:
        return Colors.grey.shade500;
      case MealEventStatus.cancelled:
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }
}
