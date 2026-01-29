import 'package:buaanyeuthuong/features/authentication/repositories/auth_repository.dart';
import 'package:buaanyeuthuong/features/beneficiary/repositories/registration_repository.dart';
import 'package:buaanyeuthuong/features/donations/repositories/donation_repository.dart';
import 'package:buaanyeuthuong/features/meal_events/repositories/meal_event_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../donations/models/donation_model.dart';
import '../views/reports_screen.dart';

class DashboardViewModel {
  final AuthRepository _authRepository;
  final RegistrationRepository _registrationRepository;
  final MealEventRepository _mealEventRepository;
  final DonationRepository _donationRepository;

  DashboardViewModel({
    required AuthRepository authRepository,
    required RegistrationRepository registrationRepository,
    required MealEventRepository mealEventRepository,
    required DonationRepository donationRepository,
  }) : _authRepository = authRepository,
       _registrationRepository = registrationRepository,
       _mealEventRepository = mealEventRepository,
       _donationRepository = donationRepository;

  //Stream cho so luot dang ky ngay hom nay
  Stream<int> getTodaysRegistrations(String restaurantId) {
    return _registrationRepository.getTodayRegistrationCountStream(
      restaurantId,
    );
  }

  //Stream cho tong so suat an da phat
  Stream<int> getTotalClaimed(String restaurantId) {
    return _registrationRepository.getTotalClaimedMealsStream(restaurantId);
  }

  //stream lay tong suat an duoc cung cap trong ngay
  Stream<int> getTodayTotalOffered(String restaurantId) {
    return _mealEventRepository.getTodayTotalOfferedMealsStream(restaurantId);
  }

  //stream lay suat an da phat trong ngay hom nay
  Stream<int> getTodayClaimed(String restaurantId) {
    return _registrationRepository.getTodaysClaimedCountStream(restaurantId);
  }

  // Xử lý logic cho màn hình danh sách chi tiết
  Stream<List<Widget>> getDetailedReportStream({
    required String reportType,
    required String restaurantId,
    required TimeRange range,
  }) {
    // Xác định khoảng thời gian
    final now = DateTime.now();
    DateTime startDate;
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (range) {
      case TimeRange.week:
        // Lấy ngày đầu tuần (Thứ 2)
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case TimeRange.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case TimeRange.allTime:
        startDate = DateTime(2020);
        break;
    }

    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    startDate = DateTime(startDate.year, startDate.month, startDate.day);

    switch (reportType) {
      case 'claimedMeals':
        //lay stream cac luot dang ky da nhan
        return _registrationRepository
            .getClaimedRegistrationsStreamByDateRange(
              restaurantId,
              startDate,
              endDate,
            )
            .asyncMap((registrations) async {
              //Dung asyncMap de thuc hien cac truy van phu
              List<Widget> tiles = [];
              for (final reg in registrations) {
                //Lay thong tin nguoi nhan va suat an
                final user = await _authRepository.getUserData(
                  reg.beneficiaryUid,
                );
                final mealEvent = await _mealEventRepository.getMealEventById(
                  reg.mealEventId,
                );
                tiles.add(
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user?.displayName ?? 'Người nhận ẩn danh'),
                    subtitle: Text(
                      'Đã nhận "${mealEvent?.description ?? 'Suất ăn treo'}"',
                    ),
                    trailing: Text(
                      DateFormat.yMd().format(reg.claimedAt!.toDate()),
                    ),
                  ),
                );
              }
              return tiles;
            });
      // --- Báo cáo Suất ăn treo được tặng ---
      case 'donatedSuspendedMeals':
        return _donationRepository
            .getDonationsStreamByDateRange(restaurantId, startDate, endDate)
            .map((donations) {
              final filteredDonations = donations.where(
                (d) => d.type == DonationType.suspended_meal,
              );
              return filteredDonations.map((don) async {
                final user = await _authRepository.getUserData(don.donorUid);
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.volunteer_activism),
                  ),
                  title: Text('${user?.displayName ?? 'Nhà hảo tâm ẩn danh'}'),
                  subtitle: Text('Đã tặng ${don.quantity} suất ăn treo'),
                  trailing: Text(
                    DateFormat('dd/MM').format(don.donatedAt.toDate()),
                  ),
                );
              }).toList();
            })
            .asyncMap((listFutureTiles) => Future.wait(listFutureTiles));


      // --- Báo cáo Quyên góp Vật phẩm ---
      case 'donatedMaterials':
        return _donationRepository
            .getDonationsStreamByDateRange(restaurantId, startDate, endDate)
            .map((donations) {
              final filteredDonations = donations.where(
                (d) => d.type == DonationType.material,
              );
              return filteredDonations.map((don) async {
                final user = await _authRepository.getUserData(don.donorUid);
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.inventory)),
                  title: Text('${user?.displayName ?? 'Nhà hảo tâm ẩn danh'}'),
                  subtitle: Text(
                    'Đã tặng ${don.quantity} ${don.unit} ${don.itemName}',
                  ),
                  trailing: Text(
                    DateFormat('dd/MM').format(don.donatedAt.toDate()),
                  ),
                );
              }).toList();
            })
            .asyncMap((listFutureTiles) => Future.wait(listFutureTiles));

      // --- Báo cáo Quyên góp Tiền mặt ---
      case 'donatedCash':
        return _donationRepository
            .getDonationsStreamByDateRange(restaurantId, startDate, endDate)
            .map((donations) {
              final filteredDonations = donations.where(
                (d) => d.type == DonationType.cash,
              );
              return filteredDonations.map((don) async {
                final user = await _authRepository.getUserData(don.donorUid);
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.monetization_on),
                  ),
                  title: Text('${user?.displayName ?? 'Nhà hảo tâm ẩn danh'}'),
                  subtitle: Text(
                    'Đã tặng ${currencyFormatter.format(don.amount)}',
                  ),
                  trailing: Text(
                    DateFormat('dd/MM').format(don.donatedAt.toDate()),
                  ),
                );
              }).toList();
            })
            .asyncMap((listFutureTiles) => Future.wait(listFutureTiles));
      default:
        return Stream.value([]); // Trả về stream rỗng nếu không có loại báo cáo
    }
  }

  Future<Map<String, num>> getReportStats(
    String restaurantId,
    TimeRange range,
  ) async {
    // Xác định khoảng thời gian
    final now = DateTime.now();
    DateTime startDate;
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (range) {
      case TimeRange.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case TimeRange.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case TimeRange.allTime:
        //Mot ngay rat xa trong qua khu
        startDate = DateTime(2020);
        break;
    }
    startDate = DateTime(startDate.year, startDate.month, startDate.day);

    //goi cac ham repository song song
    final results = await Future.wait([
      _registrationRepository.getClaimedByDateRange(
        restaurantId,
        startDate,
        endDate,
      ),
      _donationRepository.getSuspendedMealDonationCount(
        restaurantId,
        startDate,
        endDate,
      ),
      _mealEventRepository.getMealEventsCountByDateRange(
        restaurantId,
        startDate,
        endDate,
      ),
      _donationRepository.getMaterialDonationCount(
        restaurantId,
        startDate,
        endDate,
      ),
      _donationRepository.getTotalCashDonationAmount(
        restaurantId,
        startDate,
        endDate,
      ),
    ]);
    return {
      'claimedMeals': results[0] as int,
      'donatedSuspendedMeals': results[1] as int,
      'createdEvents': results[2] as int,
      'donatedMaterials': results[3] as int,
      'donatedCash': results[4] as double,
    };
  }
}
