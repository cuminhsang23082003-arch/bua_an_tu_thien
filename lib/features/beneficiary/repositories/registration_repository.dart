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
    final ref = _firestore.collection('registrations').doc(registrationId);
    try {
      final doc = await ref.get();
      if (!doc.exists) return "Mã QR không hợp lệ.";
      final reg = RegistrationModel.fromFirestore(doc);

      if (reg.status == RegistrationStatus.claimed) return "Suất này đã được nhận rồi.";
      if (reg.status == RegistrationStatus.cancelled) return "Suất này đã bị hủy.";

      await ref.update({'status': RegistrationStatus.claimed.name, 'claimedAt': Timestamp.now()});
      return "Xác nhận thành công!";
    } catch (e) {
      return "Lỗi: $e";
    }
  }

  // 2. Tìm User theo SĐT (Để check-in cho người không có smartphone)
  Future<UserModel?> findUserByPhone(String phone) async {
    final snapshot = await _firestore.collection('users')
        .where('phoneNumber', isEqualTo: phone).limit(1).get();
    if (snapshot.docs.isNotEmpty) return UserModel.fromFirestore(snapshot.docs.first);
    return null;
  }

  // 3. Tìm Vé đã đặt bằng SĐT (Nếu họ đã đặt ở nhà nhưng quên mang điện thoại)
  Future<List<RegistrationModel>> findPendingRegistrationsByPhone(String phone, String restaurantId) async {
    // Lưu ý: Tốt nhất là lưu phoneNumber vào RegistrationModel.
    // Nếu chưa có, ta phải tìm User trước -> Lấy UID -> Tìm Registration
    final user = await findUserByPhone(phone);
    if (user == null) return [];

    final snapshot = await _firestore.collection('registrations')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('beneficiaryUid', isEqualTo: user.uid)
        .where('status', isEqualTo: RegistrationStatus.registered.name)
        .get();

    return snapshot.docs.map((d) => RegistrationModel.fromFirestore(d)).toList();
  }

  // 4. Nhận trực tiếp (Direct Claim) - Dành cho người có TK nhưng chưa đặt
  Future<void> claimDirectlyForUser(String restaurantId, UserModel user) async {
    final resRef = _firestore.collection('restaurants').doc(restaurantId);
    final regRef = _firestore.collection('registrations').doc();

    return _firestore.runTransaction((transaction) async {
      final resSnapshot = await transaction.get(resRef);
      if (!resSnapshot.exists) throw Exception("Lỗi dữ liệu quán.");

      final currentCount = resSnapshot.data()?['suspendedMealsCount'] ?? 0;
      if (currentCount <= 0) throw Exception("Đã hết suất ăn treo!");

      transaction.update(resRef, {'suspendedMealsCount': FieldValue.increment(-1)});

      final newReg = RegistrationModel(
        id: regRef.id,
        beneficiaryUid: user.uid,
        mealEventId: '',
        restaurantId: restaurantId,
        status: RegistrationStatus.claimed, // Đã nhận luôn
        registeredAt: Timestamp.now(),
        claimedAt: Timestamp.now(),
      );
      transaction.set(regRef, newReg.toFirestore());
    });
  }

  // 5. Phát cho khách vãng lai (Anonymous) - Không cần tài khoản
  Future<void> claimForWalkInGuest(String restaurantId) async {
    final resRef = _firestore.collection('restaurants').doc(restaurantId);
    final regRef = _firestore.collection('registrations').doc();

    return _firestore.runTransaction((transaction) async {
      final resSnapshot = await transaction.get(resRef);
      final currentCount = resSnapshot.data()?['suspendedMealsCount'] ?? 0;
      if (currentCount <= 0) throw Exception("Đã hết suất ăn treo!");

      transaction.update(resRef, {'suspendedMealsCount': FieldValue.increment(-1)});

      transaction.set(regRef, {
        'id': regRef.id,
        'restaurantId': restaurantId,
        'beneficiaryUid': 'ANONYMOUS',
        'status': RegistrationStatus.claimed.name,
        'registeredAt': Timestamp.now(),
        'claimedAt': Timestamp.now(),
        'note': 'Khách vãng lai', // Đánh dấu
      });
    });
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
