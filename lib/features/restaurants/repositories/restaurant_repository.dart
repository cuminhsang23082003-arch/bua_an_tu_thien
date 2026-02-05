// lib/features/restaurants/repositories/restaurant_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class RestaurantRepository {
  final FirebaseFirestore _firestore;

  RestaurantRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<RestaurantModel?> getRestaurantById(String id) async {
    try {
      final doc = await _firestore.collection('restaurants').doc(id).get();
      if (doc.exists) {
        return RestaurantModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("Lỗi khi lấy thông tin quán ăn: $e");
      return null;
    }
  }

  // Lấy stream của MỘT quán ăn cụ thể dựa trên ID của nó
  Stream<RestaurantModel?> getRestaurantStreamById(String id) {
    return _firestore.collection('restaurants').doc(id).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return RestaurantModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Lấy stream của quán ăn dựa trên ID của chủ sở hữu
  Stream<RestaurantModel?> getRestaurantStreamByOwner(String ownerId) {
    return _firestore
        .collection('restaurants')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1) // Mỗi chủ quán chỉ có 1 quán
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return RestaurantModel.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }


  Future<String?> uploadImage(File imageFile, String ownerId) async {
    const String cloudName = "djvjimoti"; // Lấy từ Dashboard Cloudinary
    const String uploadPreset = "buaanyeuthuong"; // Tên preset bạn đã tạo
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = json.decode(responseString);
        final imageUrl = jsonMap['secure_url'] as String;
        print('Tải ảnh lên Cloudinary thành công! URL: $imageUrl');
        return imageUrl;
      } else {
        print('Lỗi khi tải ảnh lên Cloudinary. Status: ${response.statusCode}');
        final errorBody = await response.stream.bytesToString();
        print('Error Body: $errorBody');
        throw Exception('Failed to upload image to Cloudinary');
      }
    } catch (e) {
      print("Lỗi trong quá trình upload: $e");
      rethrow;
    }
  }

  // Tạo một quán ăn mới
  Future<void> createRestaurant(RestaurantModel restaurant) async {
    try {
      // Dùng set với doc ID tự tạo để đảm bảo chỉ có 1 quán cho mỗi owner nếu cần
      // Hoặc dùng add để Firestore tự tạo ID
      await _firestore.collection('restaurants').add(restaurant.toFirestore());
    } on FirebaseException catch (e) {
      // Xử lý lỗi nếu cần
      print("Lỗi khi tạo quán ăn: $e");
      rethrow;
    }
  }

  // Cập nhật thông tin quán ăn
  Future<void> updateRestaurant(RestaurantModel restaurant) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurant.id)
          .update(restaurant.toFirestore());
    } on FirebaseException catch (e) {
      print("Lỗi khi cập nhật quán ăn: $e");
      rethrow;
    }
  }
  // [MỚI] Cập nhật số lượng suất ăn an toàn (Atomic Increment)
  // Dùng cho tính năng: Chủ quán tự điều chỉnh số lượng (+/-)
  Future<void> updateSuspendedMealsCount(String restaurantId, int amount) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'suspendedMealsCount': FieldValue.increment(amount),
      });
    } catch (e) {
      print("Lỗi cập nhật số suất ăn: $e");
      rethrow;
    }
  }

  Future<void> updateRestaurantAndOwner({
    required RestaurantModel updatedRestaurant,
    required String ownerUid,
    required String newPhoneNumber,
  }) async {
    final restaurantRef = _firestore.collection('restaurants').doc(updatedRestaurant.id);
    final userRef = _firestore.collection('users').doc(ownerUid);

    return _firestore.runTransaction((transaction) async {
      transaction.update(restaurantRef, updatedRestaurant.toFirestore());
      transaction.update(userRef, {
        'phoneNumber': newPhoneNumber,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  // Lấy danh sách quán cho người dùng (Đã lọc kỹ)
  Stream<List<RestaurantModel>> getAllActiveRestaurantsStream() {
    return _firestore
        .collection('restaurants')
        .where('status', isEqualTo: RestaurantStatus.active.name)
        .where('isVerified', isEqualTo: true) // Chỉ hiện quán đã duyệt
        .where('isBanned', isEqualTo: false)  // Không hiện quán bị khóa
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) => RestaurantModel.fromFirestore(doc)).toList();
      } catch (e) {
        print("Lỗi parsing restaurant stream: $e");
        return [];
      }
    });
  }

  Stream<List<RestaurantModel>> getRestaurantsWithSuspendedMealsStream() {
    return _firestore
        .collection('restaurants')
        .where('status', isEqualTo: RestaurantStatus.active.name)
        .where('isVerified', isEqualTo: true)
        .where('isBanned', isEqualTo: false)
        .where('suspendedMealsCount', isGreaterThan: 0)
        .orderBy('suspendedMealsCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RestaurantModel.fromFirestore(doc)).toList());
  }

  // Lấy tất cả các quán ăn đang hoạt động (trạng thái 'active')
  Future<List<RestaurantModel>> getAllActiveRestaurants() async {
    try {
      // Giả sử bạn có trường status trong RestaurantModel
      // Nếu không có, bạn có thể bỏ .where() đi để lấy tất cả
      final snapshot = await _firestore
          .collection('restaurants')
          // .where('status', isEqualTo: 'active') // Bỏ comment nếu bạn có trường status
          .get();
      return snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Lỗi khi lấy danh sách quán ăn: $e");
      return [];
    }
  }









}
