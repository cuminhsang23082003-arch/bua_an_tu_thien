// lib/features/donations/repositories/donation_repository.dart
import 'package:buaanyeuthuong/features/donations/models/donation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationRepository {
  final FirebaseFirestore _firestore;

  DonationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Hàm chung để tạo một lượt quyên góp
  Future<void> createDonation(DonationModel donation) async {
    // 1. Tạo các tham chiếu cần thiết
    final restaurantRef = _firestore
        .collection('restaurants')
        .doc(donation.targetRestaurantId);
    final donationRef = _firestore.collection('donations').doc();

    // 2. Chạy một transaction để đảm bảo tính toàn vẹn dữ liệu
    return _firestore.runTransaction((transaction) async {
      // Logic đặc biệt chỉ dành cho Suất ăn treo:
      // Cần phải cập nhật số lượng trong document của quán ăn.
      if (donation.type == DonationType.suspended_meal) {
        if (donation.quantity == null || donation.quantity! <= 0) {
          throw Exception("Số lượng suất ăn treo phải lớn hơn 0.");
        }

        // Đọc dữ liệu của quán ăn để đảm bảo nó tồn tại
        final restaurantSnapshot = await transaction.get(restaurantRef);
        if (!restaurantSnapshot.exists) {
          throw Exception("Quán ăn này không còn tồn tại.");
        }

        // Cập nhật (tăng) số lượng suất ăn treo của quán ăn
        transaction.update(restaurantRef, {
          'suspendedMealsCount': FieldValue.increment(donation.quantity!),
        });
      }

      // Đối với quyên góp Tiền mặt hoặc Vật phẩm, ở giai đoạn này chúng ta chỉ cần
      // ghi lại lịch sử. Việc cập nhật tồn kho vật phẩm có thể là một tính năng nâng cao.

      // Ghi lại "biên lai" quyên góp vào collection 'donations'
      // Gán ID được tự động tạo vào object trước khi lưu
      final donationWithId = DonationModel(
        id: donationRef.id,
        donorUid: donation.donorUid,
        targetRestaurantId: donation.targetRestaurantId,
        targetRestaurantName: donation.targetRestaurantName,
        type: donation.type,
        donatedAt: Timestamp.now(),
        quantity: donation.quantity,
        itemName: donation.itemName,
        unit: donation.unit,
        amount: donation.amount,
        currency: donation.currency,
      );

      transaction.set(donationRef, donationWithId.toFirestore());
    });
  }

  // Hàm lấy lịch sử quyên góp của một người dùng (cho Tab "Lịch sử" sau này)
  Stream<List<DonationModel>> getMyDonationsStream(String donorUid) {
    return _firestore
        .collection('donations')
        .where('donorUid', isEqualTo: donorUid)
        .orderBy('donatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DonationModel.fromFirestore(doc))
              .toList(),
        );
  }

  //Dem so suat an treo duoc quyen gop trong 1 khoang thoi gian
  Future<int> getSuspendedMealDonationCount(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('donations')
          .where('targetRestaurantId', isEqualTo: restaurantId)
          .where('type', isEqualTo: DonationType.suspended_meal.name)
          .where(
            'donatedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('donatedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      if (snapshot.docs.isEmpty) return 0;
      // Tính tổng trường 'quantity'
      return snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['quantity'] as int? ?? 0),
      );
    } catch (e) {
      print("Lỗi đếm quyên góp: $e");
      return 0;
    }
  }

  Future<int> getMaterialDonationCount(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('donations')
          .where('targetRestaurantId', isEqualTo: restaurantId)
          .where('type', isEqualTo: DonationType.material.name)
          .where(
            'donatedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('donatedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print("Lỗi đếm quyên góp vật phẩm: $e");
      return 0;
    }
  }

  //Ham tinh tong so tien duoc quyen gop
  Future<double> getTotalCashDonationAmount(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('donations')
          .where('targetRestaurantId', isEqualTo: restaurantId)
          .where('type', isEqualTo: DonationType.cash.name)
          .where(
            'donatedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('donatedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      if (snapshot.docs.isEmpty) return 0.0;
      return snapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0),
      );
    } catch (e) {
      print("Lỗi tính tổng tiền quyên góp: $e");
      return 0.0;
    }
  }

  // Lấy danh sách các lượt quyên góp theo khoảng thời gian
  Stream<List<DonationModel>> getDonationsStreamByDateRange(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('donations')
        .where('targetRestaurantId', isEqualTo: restaurantId)
        .where(
          'donatedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('donatedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('donatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DonationModel.fromFirestore(doc))
              .toList(),
        );
  }
}
