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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Quản lý đợt phát'),
        elevation: 0,
      ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Chưa có đợt phát ăn nào.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildEventListItem(
      BuildContext context,
      MealEventModel event,
      MealEventRepository repo,
      ) {
    // Sử dụng getter thông minh từ Model
    final MealEventStatus currentStatus = event.effectiveStatus;

    // [TỐI ƯU LOGIC]
    // 1. Chỉ được SỬA khi sự kiện chưa bắt đầu
    final bool canEdit = currentStatus == MealEventStatus.scheduled;
    // 2. Được HỦY/DỪNG khi chưa bắt đầu HOẶC đang diễn ra
    final bool canCancel = currentStatus == MealEventStatus.scheduled || currentStatus == MealEventStatus.ongoing;

    Color cardColor;
    Color statusColor;

    switch (currentStatus) {
      case MealEventStatus.ongoing:
        cardColor = Colors.green.shade50;
        statusColor = Colors.green;
        break;
      case MealEventStatus.cancelled:
        cardColor = Colors.red.shade50;
        statusColor = Colors.red;
        break;
      case MealEventStatus.completed:
        cardColor = Colors.grey.shade200;
        statusColor = Colors.grey;
        break;
      default: // scheduled
        cardColor = Colors.white;
        statusColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              event.description,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
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
                    'Còn lại: ${event.remainingMeals} / ${event.totalMealsOffered} suất',
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                event.vietnameseStatus,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // [THANH CÔNG CỤ HÀNH ĐỘNG]
          if (canEdit || canCancel)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canEdit)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Sửa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditMealEventScreen(initialEvent: event),
                          ),
                        );
                      },
                    ),

                  if (canEdit && canCancel) const SizedBox(width: 12),

                  if (canCancel)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.block, size: 16),
                      label: Text(currentStatus == MealEventStatus.ongoing ? 'Dừng ngay' : 'Hủy bỏ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showDisableConfirmDialog(context, event, repo),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
      ],
    );
  }

  Future<void> _showDisableConfirmDialog(
      BuildContext context,
      MealEventModel event,
      MealEventRepository repo,
      ) async {
    final bool isOngoing = event.effectiveStatus == MealEventStatus.ongoing;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isOngoing ? 'Dừng đợt phát ăn?' : 'Hủy đợt phát ăn?'),
        content: Text(
          isOngoing
              ? 'Đợt phát ăn đang diễn ra. Bạn có chắc muốn dừng ngay bây giờ không?'
              : 'Đợt phát này chưa bắt đầu. Bạn có chắc muốn hủy bỏ nó không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isOngoing ? 'Dừng ngay' : 'Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await repo.updateMealEventStatus(event.id, MealEventStatus.cancelled);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái thành công.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}