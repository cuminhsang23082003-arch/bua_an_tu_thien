// lib/features/authentication/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  beneficiary('Người nhận'),
  admin('Admin'),
  restaurantOwner('Chủ quán ăn');

  const UserRole(this.displayName);
  final String displayName;
}

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? province;
  final String? district;
  final String? address;
  final UserRole role;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.province,
    this.district,
    this.address,
    required this.role,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.isEmailVerified = false,
    this.isActive = true,
  });

  factory UserModel.fromFirebaseUser(
      User user,
      UserRole role, {
        String? displayName,
        String? phoneNumber,
      }) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName ?? user.displayName ?? '',
      phoneNumber: phoneNumber,
      role: role,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isEmailVerified: user.emailVerified,
      isActive: true,
    );
  }

  // [ĐÃ SỬA LẠI] Nhận vào DocumentSnapshot để khớp với AdminRepository
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // Lấy data và ép kiểu an toàn
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id, // Lấy ID trực tiếp từ DocumentSnapshot
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      province: data['province'],
      district: data['district'],
      address: data['address'],
      role: UserRole.values.firstWhere(
            (e) => e.name == data['role'],
        orElse: () => UserRole.beneficiary,
      ),
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      isEmailVerified: data['isEmailVerified'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'province': province,
      'district': district,
      'address': address,
      'role': role.name,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? phoneNumber,
    String? province,
    String? district,
    String? address,
    UserRole? role,
    String? photoURL,
    DateTime? updatedAt,
    bool? isEmailVerified,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      province: province ?? this.province,
      district: district ?? this.district,
      address: address ?? this.address,
      role: role ?? this.role,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    uid, email, displayName, phoneNumber, province, district, address,
    role, photoURL, createdAt, updatedAt, isEmailVerified, isActive,
  ];
}