// lib/features/admin/repositories/admin_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../authentication/models/user_model.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../../donations/models/donation_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- THỐNG KÊ (DASHBOARD) ---
  Future<Map<String, int>> getSystemStats() async {
    try {
      final users = await _firestore.collection('users').count().get();
      final restaurants = await _firestore.collection('restaurants').count().get();
      final donations = await _firestore.collection('donations').count().get();
      final meals = await _firestore.collection('meal_events').count().get();

      return {
        'users': users.count ?? 0,
        'restaurants': restaurants.count ?? 0,
        'donations': donations.count ?? 0,
        'meals': meals.count ?? 0,
      };
    } catch (e) {
      print("Lỗi thống kê: $e");
      return {'users': 0, 'restaurants': 0, 'donations': 0, 'meals': 0};
    }
  }

  // --- QUẢN LÝ QUÁN ĂN ---

  // Lấy danh sách toàn bộ quán (để Admin quản lý)
  Stream<List<RestaurantModel>> getAllRestaurantsStream() {
    return _firestore.collection('restaurants')
    // Sắp xếp theo trạng thái duyệt (Chưa duyệt lên trước)
        .orderBy('isVerified')
        .snapshots()
        .map((s) => s.docs.map((d) => RestaurantModel.fromFirestore(d)).toList());
  }

  // Lấy danh sách quán chờ duyệt (Cho dashboard nếu cần)
  Stream<List<RestaurantModel>> getPendingRestaurantsStream() {
    return _firestore
        .collection('restaurants')
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RestaurantModel.fromFirestore(doc))
        .toList());
  }

  // [QUAN TRỌNG] Hàm này được gọi từ UI AdminScreen để Duyệt hoặc Khóa quán
  Future<void> updateRestaurantStatus(String id, {bool? isVerified, bool? isBanned}) async {
    final Map<String, dynamic> data = {};

    if (isVerified != null) {
      data['isVerified'] = isVerified;
      // Nếu duyệt thành công thì xóa lý do từ chối cũ (nếu có)
      if (isVerified) data['rejectedReason'] = null;
    }

    if (isBanned != null) {
      data['isBanned'] = isBanned;
    }

    if (data.isNotEmpty) {
      await _firestore.collection('restaurants').doc(id).update(data);
    }
  }

  // Các hàm lẻ (giữ lại để tương thích ngược nếu cần)
  Future<void> approveRestaurant(String restaurantId) async {
    await updateRestaurantStatus(restaurantId, isVerified: true);
  }

  Future<void> rejectRestaurant(String restaurantId, String reason) async {
    await _firestore.collection('restaurants').doc(restaurantId).update({
      'isVerified': false,
      'rejectedReason': reason,
    });
  }

  // --- QUẢN LÝ USER ---
  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore.collection('users')
        .orderBy('role') // Sắp xếp gom nhóm theo Role
        .limit(100)
        .snapshots()
    // [SỬA LỖI] Truyền đúng tham số là DocumentSnapshot (d)
        .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // Hàm khóa/mở khóa User
  Future<void> toggleUserBan(String uid, bool currentStatus) async {
    await _firestore.collection('users').doc(uid).update({'isActive': !currentStatus});
  }

  // Hàm này giữ lại để tương thích code cũ của bạn
  Future<void> banUser(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({'isActive': isActive});
  }

  // --- QUẢN LÝ QUYÊN GÓP (SỔ CÁI) ---
  Stream<List<DonationModel>> getAllDonationsStream() {
    return _firestore.collection('donations')
        .orderBy('donatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => DonationModel.fromFirestore(d)).toList());
  }
  Future<void> deleteRestaurant(String id) async{
    await _firestore.collection('restaurants').doc(id).delete();
  }
}