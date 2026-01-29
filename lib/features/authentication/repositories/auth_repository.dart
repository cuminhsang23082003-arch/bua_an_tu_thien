// lib/features/authentication/repositories/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // REASON: Dependency Injection. Nhận instance từ bên ngoài thay vì tự tạo.
  // Giúp cho việc testing trở nên cực kỳ dễ dàng.
  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream để theo dõi trạng thái authentication
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Lấy current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Lấy user data từ Firestore
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc.data()!, uid);
    }
    return null;
  }

  // Hàm đăng ký
  // REASON: Repository chỉ nên quan tâm đến việc thực thi, không cần biết role là gì
  // Việc tạo UserModel hoàn chỉnh sẽ do ViewModel đảm nhiệm.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    // REASON: Loại bỏ hàm isEmailExists. Firebase đã tự xử lý lỗi 'email-already-in-use'.
    // Gọi 2 lần API là không cần thiết và làm phức tạp hệ thống.
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Lưu user data vào Firestore
  Future<void> saveUserDataToFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  // Hàm đăng nhập
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Hàm đăng xuất
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUserData({
    required String uid,
    required String displayName,
    String? phoneNumber, // Thêm tham số mới
    String? province, // Thêm tham số mới
    String? district, // Thêm tham số mới
    String? address, // Địa chỉ chi tiết
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception("Người dùng chưa đăng nhập.");

    try {
      // 1. Cập nhật displayName trên Firebase Auth (chỉ có displayName)
      if (user.displayName != displayName) {
        await user.updateDisplayName(displayName);
      }

      // 2. Tạo một Map chứa các trường cần cập nhật trên Firestore
      final Map<String, dynamic> dataToUpdate = {
        'displayName': displayName,
        'updatedAt': Timestamp.now(),
      };
      if (phoneNumber != null) dataToUpdate['phoneNumber'] = phoneNumber;
      if (province != null) dataToUpdate['province'] = province;
      if (district != null) dataToUpdate['district'] = district;
      if (address != null) dataToUpdate['address'] = address;

      await _firestore.collection('users').doc(uid).update(dataToUpdate);
    } catch (e) {
      rethrow;
    }
  }

  //HÀM KIỂM TRA SĐT
Future <bool> isPhoneNumberExists(String phoneNumber) async{
    try{
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber',isEqualTo: phoneNumber)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    }catch (e){
      print("Lỗi khi kiểm tra SĐT: $e");
      // Trả về false để tránh chặn người dùng nếu có lỗi mạng
      return false;
    }
}

  Future <bool> isEmailExists(String email) async{
    try{
      final querySnapshot = await _firestore
          .collection('users')
          .where('email',isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    }catch (e){
      print("Lỗi khi kiểm tra email: $e");
      // Trả về false để tránh chặn người dùng nếu có lỗi mạng
      return false;
    }
  }


}
