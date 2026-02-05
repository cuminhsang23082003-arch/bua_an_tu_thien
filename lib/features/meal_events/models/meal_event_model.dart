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
  final String restaurantName;
  final String province;
  final String district;
  final GeoPoint location;
  final Timestamp eventDate;
  final String startTime;
  final String endTime;
  final int totalMealsOffered;
  final int remainingMeals;
  final MealEventType mealType;
  final String description;
  final MealEventStatus status;
  final int registeredRecipientsCount;
  final Timestamp createdAt;

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

      // [QUAN TRỌNG] Ép kiểu an toàn để tránh lỗi Null
      eventDate: (data['eventDate'] as Timestamp?) ?? Timestamp.now(),

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

      // [QUAN TRỌNG] Ép kiểu an toàn
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'province': province,
      'district': district,
      'location': location,
      'eventDate': eventDate,
      'startTime': startTime,
      'endTime': endTime,
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
    id, restaurantId, restaurantName, province, district, location, eventDate,
    startTime, endTime, totalMealsOffered, remainingMeals, mealType,
    description, status, registeredRecipientsCount, createdAt
  ];

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
      mealType: mealType,
      description: description ?? this.description,
      status: status ?? this.status,
      registeredRecipientsCount: registeredRecipientsCount ?? this.registeredRecipientsCount,
      createdAt: createdAt,
    );
  }

  // --- LOGIC TÍNH TOÁN TRẠNG THÁI ---

  TimeOfDay _timeOfDayFromString(String timeString) {
    if (timeString.isEmpty) return const TimeOfDay(hour: 0, minute: 0);
    try {
      final format = DateFormat.jm();
      final dt = format.parse(timeString);
      return TimeOfDay.fromDateTime(dt);
    } catch (e) {
      try {
        final parts = timeString.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e2) {
        return const TimeOfDay(hour: 0, minute: 0);
      }
    }
  }

  MealEventStatus get effectiveStatus {
    if (status == MealEventStatus.completed || status == MealEventStatus.cancelled) {
      return status;
    }

    final TimeOfDay start = _timeOfDayFromString(startTime);
    final TimeOfDay end = _timeOfDayFromString(endTime);
    final DateTime eventDay = eventDate.toDate();

    final DateTime startDateTime = DateTime(eventDay.year, eventDay.month, eventDay.day, start.hour, start.minute);
    DateTime endDateTime = DateTime(eventDay.year, eventDay.month, eventDay.day, end.hour, end.minute);

    // Xử lý qua đêm (VD: 22:00 -> 02:00 sáng hôm sau)
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final now = DateTime.now();

    if (now.isAfter(endDateTime)) {
      return MealEventStatus.completed;
    } else if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
      return MealEventStatus.ongoing;
    } else {
      return MealEventStatus.scheduled;
    }
  }

  String get vietnameseStatus {
    switch (effectiveStatus) {
      case MealEventStatus.scheduled:
        return 'Sắp diễn ra';
      case MealEventStatus.ongoing:
        return 'Đang diễn ra';
      case MealEventStatus.completed:
        return 'Đã kết thúc';
      case MealEventStatus.cancelled:
        return 'Đã hủy';
      default:
        return 'Không rõ';
    }
  }
}