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

  // Hàm này trả về Stream
  Stream<List<RestaurantModel>> getAllActiveRestaurantsStream() {
    return _firestore
        .collection('restaurants')
        .where('status', isEqualTo: RestaurantStatus.active.name)
        .snapshots() // Dùng snapshots() thay vì get() để tạo Stream
        .map((snapshot) {
          try {
            // Chuyển đổi mỗi document trong snapshot thành một RestaurantModel
            return snapshot.docs
                .map((doc) => RestaurantModel.fromFirestore(doc))
                .toList();
          } catch (e) {
            print("Lỗi khi parsing restaurant stream: $e");
            return []; // Trả về danh sách rỗng nếu có lỗi parsing
          }
        });
  }

  Stream<List<RestaurantModel>> getRestaurantsWithSuspendedMealsStream() {
    return _firestore
        .collection('restaurants')
        .where('status', isEqualTo: RestaurantStatus.active.name)
        .where('suspendedMealsCount', isGreaterThan: 0)
        .orderBy('suspendedMealsCount', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RestaurantModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateRestaurantAndOwner({
    required RestaurantModel updatedRestaurant,
    required String ownerUid,
    required String newPhoneNumber,
  }) async {
    // 1. Tạo các tham chiếu cần thiết
    final restaurantRef = _firestore.collection('restaurants').doc(updatedRestaurant.id);
    final userRef = _firestore.collection('users').doc(ownerUid);

    // 2. Chạy một transaction
    return _firestore.runTransaction((transaction) async {
      // 3. Cập nhật document của quán ăn
      transaction.update(restaurantRef, updatedRestaurant.toFirestore());

      // 4. Cập nhật document của người dùng (chủ quán)
      transaction.update(userRef, {
        'phoneNumber': newPhoneNumber,
        'updatedAt': Timestamp.now(),
      });
    });
  }


}
