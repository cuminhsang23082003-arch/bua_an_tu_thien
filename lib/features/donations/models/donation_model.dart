// lib/features/donations/models/donation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// [SỬA] Mở rộng enum
enum DonationType {
  suspended_meal, // Suất ăn treo
  material,       // Vật phẩm (gạo, rau...)
  cash            // Tiền mặt
}

class DonationModel extends Equatable {
  final String id;
  final String donorUid;
  final String targetRestaurantId;
  final String targetRestaurantName;
  final DonationType type;
  final Timestamp donatedAt;

  // Thuộc tính cho từng loại
  final int? quantity;      // Dùng cho suất ăn treo và vật phẩm
  final String? itemName;   // Tên vật phẩm
  final String? unit;       // Đơn vị vật phẩm (kg, thùng...)
  final double? amount;     // Số tiền quyên góp
  final String? currency;   // Đơn vị tiền tệ (VND)

  const DonationModel({
    required this.id,
    required this.donorUid,
    required this.targetRestaurantId,
    required this.targetRestaurantName,
    required this.type,
    required this.donatedAt,
    // Các thuộc tính mới là nullable
    this.quantity,
    this.itemName,
    this.unit,
    this.amount,
    this.currency,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'donorUid': donorUid,
      'targetRestaurantId': targetRestaurantId,
      'targetRestaurantName': targetRestaurantName,
      'type': type.name,
      'donatedAt': donatedAt,
      // Chỉ ghi các trường có giá trị vào Firestore
      if (quantity != null) 'quantity': quantity,
      if (itemName != null) 'itemName': itemName,
      if (unit != null) 'unit': unit,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
    };
  }

  // Thêm fromFirestore để có thể xem lại lịch sử
  factory DonationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonationModel(
      id: doc.id,
      donorUid: data['donorUid'] ?? '',
      targetRestaurantId: data['targetRestaurantId'] ?? '',
      targetRestaurantName: data['targetRestaurantName'] ?? '',
      type: DonationType.values.firstWhere(
              (e) => e.name == data['type'],
          orElse: () => DonationType.suspended_meal
      ),
      donatedAt: data['donatedAt'] ?? Timestamp.now(),
      quantity: data['quantity'],
      itemName: data['itemName'],
      unit: data['unit'],
      amount: (data['amount'] as num?)?.toDouble(), // Chuyển đổi an toàn
      currency: data['currency'],
    );
  }

  @override
  List<Object?> get props => [id, donorUid, targetRestaurantId, donatedAt];
}