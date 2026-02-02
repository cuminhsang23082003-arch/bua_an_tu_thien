// lib/features/restaurants/models/restaurant_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RestaurantStatus { active, pending_approval, closed }

class RestaurantModel extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String province;
  final String district;
  final String address;
  final GeoPoint location;
  final String phoneNumber;
  final int suspendedMealsCount; //suat an treo
  final String description;
  final RestaurantStatus status;
  final Map<String, String> operatingHours;
  final String? imageUrl;
  final bool isVerified;
  final String? rejectedReason;
  final bool isBanned;
  final DateTime createdAt;

  const RestaurantModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.province,
    required this.district,
    required this.address,
    required this.location,
    required this.phoneNumber,
    this.suspendedMealsCount = 0,// mac dinh la 0
    required this.description,
    this.status = RestaurantStatus.active,
    this.operatingHours = const {},
    this.imageUrl,
    required this.createdAt,
    this.isVerified = false,
    this.isBanned = false,
    this.rejectedReason,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      province: data['province'] ?? '',
      district: data['district'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      phoneNumber: data['phoneNumber'] ?? '',
      suspendedMealsCount: data['suspendedMealsCount'] ?? 0,
      description: data['description'] ?? '',
      status: RestaurantStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => RestaurantStatus.pending_approval,
      ),
      operatingHours: Map<String, String>.from(data['operatingHours'] ?? {}),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      isVerified: data['isVerified'] ?? false,
      isBanned: data['isBanned'] ?? false,
      rejectedReason: data['rejectedReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      // [SỬA LỖI] Sửa lỗi chính tả
      'province': province,
      'district': district,
      'address': address,
      'location': location,
      'phoneNumber': phoneNumber,
      'suspendedMealsCount': suspendedMealsCount,
      'description': description,
      'status': status.name,
      'operatingHours': operatingHours,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
      'isBanned': isBanned,
      'rejectedReason': rejectedReason,
    };
  }

  // [SỬA LỖI] Thêm province và district vào props
  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    province,
    district,
    address,
    location,
    phoneNumber,
    suspendedMealsCount,
    description,
    status,
    operatingHours,
    imageUrl,
    isVerified,
    isBanned,
    rejectedReason,
    createdAt,
  ];

  RestaurantModel copyWith({
    String? name,
    String? province,
    String? district,
    String? address,
    GeoPoint? location,
    String? phoneNumber,
    int? suspendedMealsCount,
    String? description,
    RestaurantStatus? status,
    Map<String, String>? operatingHours,
    String? imageUrl,
    bool? isVerified,
    bool? isBanned,
    String? rejectedReason,
  }) {
    return RestaurantModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      province: province ?? this.province,
      district: district ?? this.district,
      address: address ?? this.address,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      suspendedMealsCount: suspendedMealsCount ?? this.suspendedMealsCount,
      description: description ?? this.description,
      status: status ?? this.status,
      operatingHours: operatingHours ?? this.operatingHours,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      createdAt: createdAt,
    );
  }
}