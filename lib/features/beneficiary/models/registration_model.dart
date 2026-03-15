

// lib/features/beneficiary/models/registration_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RegistrationStatus { registered, claimed, cancelled}

class RegistrationModel extends Equatable {
  final String id;
  final String beneficiaryUid;
  final String mealEventId;
  final String restaurantId;
  final RegistrationStatus status;
  final Timestamp registeredAt;
  final Timestamp? claimedAt;
  //Luu du thua de load nhanh
  final String restaurantName;
  final String restaurantAddress;
  final String eventDescription;
  final String eventTimeDisplay;


  const RegistrationModel({
    required this.id,
    required this.beneficiaryUid,
    required this.mealEventId,
    required this.restaurantId,
    this.status = RegistrationStatus.registered,
    required this.registeredAt,
    this.claimedAt,

    this.restaurantName ='',
    this.restaurantAddress ='',
    this.eventDescription ='',
    this.eventTimeDisplay ='',
});

  Map<String, dynamic> toFirestore(){
    return{
      'beneficiaryUid':beneficiaryUid,
      'mealEventId': mealEventId,
      'restaurantId':restaurantId,
      'status':status.name,
      'registeredAt':registeredAt,
      'claimedAt':claimedAt,
      'restaurantName' : restaurantName,
      'restaurantAddress' : restaurantAddress,
      'eventDescription' : eventDescription,
      'eventTimeDisplay' : eventTimeDisplay,
    };
  }

  factory RegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegistrationModel(
      id: doc.id,
      beneficiaryUid: data['beneficiaryUid'] ?? '',
      mealEventId: data['mealEventId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      status: RegistrationStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => RegistrationStatus.registered,
      ),
      registeredAt: (data['registeredAt'] as Timestamp?) ?? Timestamp.now(),
      claimedAt: data['claimedAt'] as Timestamp?,
      restaurantName: data['restaurantName'] ?? 'Đang tải...',
      restaurantAddress: data['restaurantAddress'] ?? '',
      eventDescription: data['eventDescription'] ?? 'Suất ăn từ thiện',
      eventTimeDisplay: data['eventTimeDisplay'] ?? '',

    );
  }

  @override
  List<Object?> get props =>  [id, beneficiaryUid, mealEventId];

}