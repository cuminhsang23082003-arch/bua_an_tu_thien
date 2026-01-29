// lib/features/beneficiary/repositories/registration_repository.dart
import 'package:buaanyeuthuong/features/authentication/models/user_model.dart';
import 'package:buaanyeuthuong/features/beneficiary/models/registration_model.dart';
import 'package:buaanyeuthuong/features/meal_events/models/meal_event_model.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationRepository {
  final FirebaseFirestore _firestore;

  RegistrationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<RegistrationModel>> getMyRegistrationsStream(
      String beneficiaryUid,) {
    return _firestore
        .collection('registrations')
        .where('beneficiaryUid', isEqualTo: beneficiaryUid)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs
              .map((doc) => RegistrationModel.fromFirestore(doc))
              .toList(),
    );
  }

  // [SỬA LỖI] Sửa lỗi chính tả tên hàm và định nghĩa tham số
  Future<void> registerForMealEvent(MealEventModel mealEvent,
      UserModel user,) async {
    final eventRef = _firestore.collection('mealEvents').doc(mealEvent.id);
    final registrationRef = _firestore.collection('registrations').doc();
    final registrationsCollection = _firestore.collection('registrations');

    return _firestore.runTransaction((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw Exception('Đợt phát ăn không còn tồn tại!');
      }
      final currentEventData = MealEventModel.fromFirestore(eventSnapshot);

      if (currentEventData.remainingMeals <= 0) {
        throw Exception('Rất tiếc, suất ăn đã được đăng ký hết!');
      }
      if (currentEventData.effectiveStatus != MealEventStatus.scheduled &&
          currentEventData.effectiveStatus != MealEventStatus.ongoing) {
        throw Exception("Đợt phát ăn này không còn mở để đăng ký.");
      }

      final existingRegistrationQuery = registrationsCollection
          .where('beneficiaryUid', isEqualTo: user.uid)
          .where('mealEventId', isEqualTo: mealEvent.id)
          .limit(1);

      final existingDocs = await existingRegistrationQuery.get();
      if (existingDocs.docs.isNotEmpty) {
        throw Exception("Bạn đã đăng ký nhận suất ăn này rồi.");
      }

      transaction.update(eventRef, {
        'remainingMeals': FieldValue.increment(-1),
        'registeredRecipientsCount': FieldValue.increment(1),
      });

      final newRegistration = RegistrationModel(
        id: registrationRef.id,
        beneficiaryUid: user.uid,
        mealEventId: mealEvent.id,
        restaurantId: mealEvent.restaurantId,
        registeredAt: Timestamp.now(),
      );
      transaction.set(registrationRef, newRegistration.toFirestore());
    });
  }

  Future<void> claimSuspendedMeal(RestaurantModel restaurant,
      UserModel user,) async {
    final existingRegistrationQuery = _firestore
        .collection('registrations')
        .where('beneficiaryUid', isEqualTo: user.uid)
        .where('restaurantId', isEqualTo: restaurant.id)
        .where('mealEventId', isEqualTo: '')
        .where('status', isEqualTo: RegistrationStatus.registered.name)
        .limit(1);

    final existingDocs = await existingRegistrationQuery.get();
    if (existingDocs.docs.isNotEmpty) {
      throw Exception("Bạn đã có một suất ăn treo đang chờ nhận tại quán này.");
    }

    final restaurantRef = _firestore
        .collection('restaurants')
        .doc(restaurant.id);
    final registrationRef = _firestore.collection('registrations').doc();

    return _firestore.runTransaction((transaction) async {
      final restaurantSnapshot = await transaction.get(restaurantRef);
      if (!restaurantSnapshot.exists) throw Exception("Quán ăn không tồn tại.");

      final currentRestaurant = RestaurantModel.fromFirestore(
        restaurantSnapshot,
      );
      if (currentRestaurant.suspendedMealsCount <= 0) {
        throw Exception("Rất tiếc, quán đã hết suất ăn treo.");
      }

      transaction.update(restaurantRef, {
        'suspendedMealsCount': FieldValue.increment(-1),
      });

      final newRegistration = RegistrationModel(
        id: registrationRef.id,
        beneficiaryUid: user.uid,
        mealEventId: '',
        restaurantId: restaurant.id,
        status: RegistrationStatus.registered,
        registeredAt: Timestamp.now(),
      );
      transaction.set(registrationRef, newRegistration.toFirestore());
    });
  }

  Future<String> claimRegistration(String registrationId) async {
    final registrationRef = _firestore
        .collection('registrations')
        .doc(registrationId);

    final mealEventsCollection = _firestore.collection('mealEvents');
    final restaurantsCollection = _firestore.collection('restaurants');
    try {
      final doc = await registrationRef.get();
      if (!doc.exists) {
        return "Mã QR không hợp lệ hoặc không tồn tại.";
      }

      final registration = RegistrationModel.fromFirestore(doc);

      if (registration.status == RegistrationStatus.claimed) {
        return "Suất ăn này đã được nhận trước đó.";
      }
      if (registration.status == RegistrationStatus.cancelled) {
        return "Lượt đăng ký này đã bị hủy.";
      }

      final bool isSuspendedMeal = registration.mealEventId.isEmpty;

      if(isSuspendedMeal){
        final restaurantDoc = await restaurantsCollection.doc(registration.restaurantId).get();
        if(!restaurantDoc.exists || restaurantDoc.data()? ['status'] != RestaurantStatus.active.name){
          return "Không thể xác nhận. Quán ăn này có thể đã đóng cửa hoặc không còn hoạt động.";
        }
      }else{
        // Nếu là ĐỢT PHÁT ĂN, kiểm tra trạng thái của ĐỢT PHÁT ĂN
        final mealEventDoc = await mealEventsCollection.doc(registration.mealEventId).get();
        if(!mealEventDoc.exists){
          return "Không thể xác nhận. Đợt phát ăn này không còn tồn tại.";
        }

        final mealEvent = MealEventModel.fromFirestore(mealEventDoc);
        final currentStatus = mealEvent.effectiveStatus;

        if (currentStatus != MealEventStatus.scheduled && currentStatus != MealEventStatus.ongoing) {
          return "Không thể xác nhận. Đợt phát ăn này đã kết thúc hoặc đã bị hủy.";
        }
      }

      await registrationRef.update({
        'status': RegistrationStatus.claimed.name,
        'claimedAt': Timestamp.now(),
      });
      return "Xác nhận thành công!";
    } on FirebaseException catch (e) {
      return "Lỗi Firestore: ${e.message}";
    } catch (e) {
      return "Đã có lỗi không mong muốn xảy ra.";
    }
  }

  //Thong ke
  Stream<int> getTodayRegistrationCountStream(String restaurantId) {
    //lay thoi diem bat dau cua ngay hom nay
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTodayTimestamp = Timestamp.fromDate(startOfToday);

    return _firestore
        .collection('registrations')
        .where('restaurantId', isEqualTo: restaurantId)
    //lay cac luot dang ky duoc tao tu ngay hom nay tro di
        .where('registeredAt', isGreaterThanOrEqualTo: startOfTodayTimestamp)
        .snapshots()
        .map((snapshot) => snapshot.size); //size tra ve so luong document
  }

  Stream<int> getTodaysClaimedCountStream(String restaurantId) {
    final now = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final end = Timestamp.fromDate(DateTime(now.year, now.month, now.day, 23, 59, 59));
    return _firestore
        .collection('registrations')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: RegistrationStatus.claimed.name)
        .where('claimedAt', isGreaterThanOrEqualTo: start)
        .where('claimedAt', isLessThanOrEqualTo: end)
        .snapshots()
        .map((s) => s.size);
  }

  Stream <int> getTotalClaimedMealsStream(String restaurantId) {
    return _firestore
        .collection('registrations')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: RegistrationStatus.claimed.name)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  //Dem so luot da nhan (claimed) trong mot khoang thoi gian
  Future <int> getClaimedByDateRange(String restaurantId, DateTime startDate,
      DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('registrations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: RegistrationStatus.claimed.name)
          .where(
          'claimedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('claimedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Lỗi đếm lượt đã nhận: $e"');
      return 0;
    }
  }

  Stream<List<RegistrationModel>> getClaimedRegistrationsStreamByDateRange(
      String restaurantId, DateTime startDate, DateTime endDate) {
    return _firestore
        .collection('registrations')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: RegistrationStatus.claimed.name)
        .where('claimedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('claimedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('claimedAt', descending: true) // Mới nhất lên đầu
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList());
  }
}
