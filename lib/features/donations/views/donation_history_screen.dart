// lib/features/donations/views/donation_history_screen.dart
import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/donations/models/donation_model.dart';
import 'package:buaanyeuthuong/features/donations/repositories/donation_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final donationRepo = context.read<DonationRepository>();
    final authUser = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử quyên góp')),
      body: authUser == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem lịch sử.'))
          : StreamBuilder<List<DonationModel>>(
        stream: donationRepo.getMyDonationsStream(authUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Không thể tải lịch sử.'));
          }
          final donations = snapshot.data ?? [];
          if (donations.isEmpty) {
            return const Center(
              child: Text('Bạn chưa có hoạt động quyên góp nào.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              return _buildDonationCard(context, donations[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(BuildContext context, DonationModel donation) {
    String title = 'Quyên góp';
    String subtitle = 'Đến: ${donation.targetRestaurantName}\n'
        'Ngày: ${DateFormat('dd/MM/yyyy, hh:mm a').format(donation.donatedAt.toDate())}';

    switch (donation.type) {
      case DonationType.suspended_meal:
        title = 'Tặng ${donation.quantity} suất ăn treo';
        break;
      case DonationType.material:
        title = 'Tặng ${donation.quantity} ${donation.unit} ${donation.itemName}';
        break;
      case DonationType.cash:
        final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
        title = 'Tặng ${formatCurrency.format(donation.amount)}';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.volunteer_activism),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        isThreeLine: true,
      ),
    );
  }
}