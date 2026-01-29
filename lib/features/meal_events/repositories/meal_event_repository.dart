// lib/features/meal_events/repositories/meal_event_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_event_model.dart';

class MealEventRepository {
  final FirebaseFirestore _firestore;

  MealEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Hàm để tạo một đợt phát ăn mới
  Future<void> createMealEvent(MealEventModel event) async {
    try {
      await _firestore.collection('mealEvents').add(event.toFirestore());
    } on FirebaseException catch (e) {
      print("Lỗi khi tạo đợt phát ăn: $e");
      rethrow;
    }
  }

  Future<void> updateMealEvent(MealEventModel event) async {
    try {
      await _firestore
          .collection('mealEvents')
          .doc(event.id)
          .update(event.toFirestore());
    } on FirebaseException catch (e) {
      print('Lỗi khi cập nhật đợt phát suất ăn: $e');
      rethrow;
    }
  }

  // Dùng cho các hành động thay đổi TRẠNG THÁI, chỉ cập nhật 1 trường
  Future<void> updateMealEventStatus(
    String eventId,
    MealEventStatus newStatus,
  ) async {
    try {
      await _firestore.collection('mealEvents').doc(eventId).update({
        'status': newStatus.name,
        // .name sẽ chuyển enum thành String (ví dụ: 'cancelled')
      });
    } on FirebaseException catch (e) {
      print("Lỗi khi cập nhật trạng thái đợt phát ăn: $e");
      rethrow;
    }
  }

  // Lấy danh sách các đợt phát ăn của một quán cụ thể (dưới dạng Stream)
  // Sắp xếp theo ngày sự kiện, sự kiện mới nhất sẽ được hiển thị trước
  Stream<List<MealEventModel>> getMealEventsForRestaurantStream(
    String restaurantId,
  ) {
    return _firestore
        .collection('mealEvents')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) {
          // Chuyển đổi mỗi document thành một đối tượng MealEventModel
          return snapshot.docs
              .map((doc) => MealEventModel.fromFirestore(doc))
              .toList();
        });
  }

  Stream<List<MealEventModel>> getAllActiveMealEventsStream() {
    return _firestore
        .collection('mealEvents')
        // Điều kiện 1: Chỉ lấy các sự kiện chưa bị hủy hoặc hoàn thành thủ công.
        .where('status', isEqualTo: MealEventStatus.scheduled.name)
        // Điều kiện 2 (Tùy chọn nhưng hiệu quả): Chỉ lấy các sự kiện có suất ăn.
        .where('remainingMeals', isGreaterThan: 0)
        // Sắp xếp theo ngày gần nhất trước
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MealEventModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<MealEventModel?> getMealEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('mealEvents').doc(eventId).get();
      if (doc.exists) {
        return MealEventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("Lỗi khi lấy MealEvent by ID: $e");
      return null;
    }
  }

  Stream<List<MealEventModel>> getRecentScheduledEventsStream({int limit = 5}) {
    return _firestore
        .collection('mealEvents')
        // Chỉ lấy các sự kiện chưa bị hủy hoặc hoàn thành thủ công.
        .where('status', isEqualTo: MealEventStatus.scheduled.name)
        // Chỉ lấy các sự kiện có suất ăn.
        .where('remainingMeals', isGreaterThan: 0)
        // Sắp xếp theo ngày tạo mới nhất (để lấy các sự kiện mới nhất)
        .orderBy('createdAt', descending: true)
        .limit(limit) // Giới hạn chỉ 5 kết quả
        .snapshots()
        .map((snapshot) {
          // Vì đã sắp xếp theo ngày TẠO, chúng ta cần sắp xếp lại theo ngày DIỄN RA ở client
          var events = snapshot.docs
              .map((doc) => MealEventModel.fromFirestore(doc))
              .toList();
          events.sort(
            (a, b) => a.eventDate.compareTo(b.eventDate),
          ); // Sắp xếp lại theo ngày gần nhất
          return events;
        });
  }

  //Lấy tổng số suất ăn được cung cấp trong các đợt phát của ngày hôm nay
  Stream<int> getTodayTotalOfferedMealsStream(String restaurantId) {
    final now = DateTime.now();
    final startOfToday = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day),
    );
    final endOfToday = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    return _firestore
        .collection('mealEvents')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('eventDate', isGreaterThanOrEqualTo: startOfToday)
        .where('eventDate',isLessThanOrEqualTo: endOfToday)
        .snapshots()
        .map((snapshot){
          if(snapshot.docs.isEmpty) return 0;
          return snapshot.docs.fold<int>(0,(sum,doc) => sum + (doc.data()['totalMealsOffered'] as int? ?? 0));
    });
  }

  // Dem so luong dot phat an duoc tao trong 1 khoang thoi gian
Future <int> getMealEventsCountByDateRange(String restaurantId, DateTime startDate, DateTime endDate) async{
    try{
      final snapshot = await _firestore
          .collection('mealEvents')
          .where('restaurantId',isEqualTo: restaurantId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt',isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .count()
          .get();
      return snapshot.count??0;
    }catch (e) {
      print("Lỗi đếm số đợt phát ăn: $e");
      return 0;
    }
}
}
