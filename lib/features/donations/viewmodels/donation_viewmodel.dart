// lib/features/donations/viewmodels/donation_viewmodel.dart
import 'package:buaanyeuthuong/features/donations/models/donation_model.dart';
import 'package:buaanyeuthuong/features/donations/repositories/donation_repository.dart';
import 'package:flutter/material.dart';

class DonationViewModel extends ChangeNotifier {
  final DonationRepository _donationRepository;

  DonationViewModel({required DonationRepository donationRepository})
      : _donationRepository = donationRepository;

  bool _isDonating = false;
  bool get isDonating => _isDonating;

  // Hàm chung để xử lý mọi loại quyên góp
  Future<String?> makeDonation(DonationModel donation) async {
    _isDonating = true;
    notifyListeners();
    try {
      // Gọi đến hàm trong repository
      await _donationRepository.createDonation(donation);
      _isDonating = false;
      notifyListeners();
      return null; // Trả về null nếu thành công
    } catch (e) {
      _isDonating = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', ''); // Trả về thông báo lỗi nếu thất bại
    }
  }
}