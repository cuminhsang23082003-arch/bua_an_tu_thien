// lib/features/meal_events/models/meal_event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
 import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum MealEventType { free_meal, pending_meal_pickup }
enum MealEventStatus { scheduled, ongoing, completed, cancelled }

class MealEventModel extends Equatable {
  final String id;
  final String restaurantId;
  final String restaurantName; // Denormalized
  final Timestamp eventDate;   // Giữ là Timestamp để truy vấn dễ dàng
  final String startTime;
  final String endTime;
  final int totalMealsOffered;
  final int remainingMeals;
  final MealEventType mealType;
  final String description;
  final MealEventStatus status;
  final int registeredRecipientsCount;
  final String province;
  final String district;
  final GeoPoint location;
  final Timestamp createdAt;   // Giữ là Timestamp
  //Getter để tính toán trạng thái thực tế

  const MealEventModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.province,
    required this.district,
    required this.location,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.totalMealsOffered,
    required this.remainingMeals,
    required this.mealType,
    required this.description,
    this.status = MealEventStatus.scheduled,
    this.registeredRecipientsCount = 0,
    required this.createdAt,
  });

  factory MealEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealEventModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      province: data['province'] ?? 'Không rõ',
      district: data['district'] ?? 'Không rõ',
      location: data['location'] ?? const GeoPoint(0, 0),
      eventDate: data['eventDate'] ?? Timestamp.now(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      totalMealsOffered: data['totalMealsOffered'] ?? 0,
      remainingMeals: data['remainingMeals'] ?? 0,
      mealType: MealEventType.values.firstWhere(
            (e) => e.name == data['mealType'],
        orElse: () => MealEventType.free_meal,
      ),
      description: data['description'] ?? '',
      status: MealEventStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => MealEventStatus.scheduled,
      ),
      registeredRecipientsCount: data['registeredRecipientsCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'province': province,
      'district' : district,
      'location' : location,
      'eventDate': eventDate,
      'startTime' : startTime,
      'endTime' : endTime,
      'totalMealsOffered': totalMealsOffered,
      'remainingMeals': remainingMeals,
      'mealType': mealType.name,
      'description': description,
      'status': status.name,
      'registeredRecipientsCount': registeredRecipientsCount,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id, restaurantId, restaurantName, province, district,location, eventDate,
    startTime, endTime, totalMealsOffered, remainingMeals, mealType,
    description, status, registeredRecipientsCount, createdAt
  ];
  // Hàm copyWith đã được sửa hoàn chỉnh
  MealEventModel copyWith({
    String? restaurantName,
    String? province,
    String? district,
    GeoPoint? location,
    Timestamp? eventDate,
    String? startTime,
    String? endTime,
    int? totalMealsOffered,
    int? remainingMeals,
    String? description,
    MealEventStatus? status,
    int? registeredRecipientsCount,
  }) {
    return MealEventModel(
      id: id,
      restaurantId: restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      province: province ?? this.province,
      district: district ?? this.district,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalMealsOffered: totalMealsOffered ?? this.totalMealsOffered,
      remainingMeals: remainingMeals ?? this.remainingMeals,
      mealType: mealType, // Thường không thay đổi
      description: description ?? this.description,
      status: status ?? this.status,
      registeredRecipientsCount: registeredRecipientsCount ?? this.registeredRecipientsCount,
      createdAt: createdAt, // Không thay đổi
    );
  }


  //Hàm helper để chuyển đổi String -> TimeOfDay
  TimeOfDay _timeOfDayFromString(String timeString) {
    if (timeString.isEmpty) return const TimeOfDay(hour: 0, minute: 0);
    try {
      // Thử định dạng AM/PM trước (ví dụ: "5:08 PM")
      final format = DateFormat.jm();
      final dt = format.parse(timeString);
      return TimeOfDay.fromDateTime(dt);
    } catch (e) {
      // Nếu thất bại, thử định dạng 24h (ví dụ: "17:08")
      try {
        final parts = timeString.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e2) {
        // Nếu vẫn thất bại, trả về một giá trị mặc định an toàn
        return const TimeOfDay(hour: 0, minute: 0);
      }
    }
  }


  MealEventStatus get effectiveStatus{
    if (status == MealEventStatus.completed || status == MealEventStatus.cancelled) {
      return status;
    }

    // Chuyển đổi String thành TimeOfDay trước khi tính toán
    final TimeOfDay start = _timeOfDayFromString(startTime);
    final TimeOfDay end = _timeOfDayFromString(endTime);
    final DateTime eventDay = eventDate.toDate();
    final DateTime startDateTime = DateTime(eventDay.year, eventDay.month, eventDay.day, start.hour, start.minute);
    DateTime endDateTime = DateTime(eventDay.year, eventDay.month, eventDay.day, end.hour, end.minute);
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }
    final now = DateTime.now();

    if (now.isAfter(endDateTime)) {
      // Nếu đã qua giờ kết thúc
      return MealEventStatus.completed;
    } else if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
      // Nếu đang trong khoảng thời gian diễn ra
      return MealEventStatus.ongoing;
    } else {
      // Nếu chưa đến giờ bắt đầu
      return MealEventStatus.scheduled;
    }

  }


 // [THÊM MỚI] Hàm helper để dịch trạng thái sang tiếng Việt
String get vietnameseStatus{
    switch(effectiveStatus){
      case MealEventStatus.scheduled:
        return 'Đã lên lịch';      // Đợt phát ăn đã được lên lịch nhưng chưa đến giờ bắt đầu.
      case MealEventStatus.ongoing:
        return 'Đang diễn ra';    //Khi thời gian hiện tại nằm trong khoảng từ startTime đến endTime của eventDate.
      case MealEventStatus.completed:
        return 'Đã hoàn thành'; //Tự động: Khi thời gian hiện tại vượt qua eventDate + endTime. Khi trở về 0 (hết suất ăn).

      case MealEventStatus.cancelled: //Đợt phát ăn đã bị hủy vì một lý do nào đó.
        return 'Đã vô hiệu hóa';
      default:
        return 'Không rõ';
    }
}
}