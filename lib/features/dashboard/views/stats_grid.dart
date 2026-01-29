import 'package:buaanyeuthuong/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class StatsGrid extends StatelessWidget {

  final RestaurantModel restaurant;

  const StatsGrid({Key? key, required this.restaurant}) :super(key: key);


  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.read<DashboardViewModel>();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        //Card 1: dang ky hom nay
        _buildStatCard(
          context: context,
          title: 'Đăng ký hôm nay',
          icon: Icons.today,
          color: Colors.blue,
          stream: dashboardViewModel.getTodaysRegistrations(restaurant.id),
        ),
        // Card 2: đã phát hôm nay
        _buildStatCard(
          context: context,
          title: 'Đã phát hôm nay',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          stream: dashboardViewModel.getTodayClaimed(restaurant.id),
        ),
        // Card 3: Suất ăn treo
        StreamBuilder<RestaurantModel?>(
          stream: context.read<RestaurantRepository>().getRestaurantStreamById(
              restaurant.id),
          builder: (context, snapshot) {
            final count = snapshot.data?.suspendedMealsCount ?? 0;
            return _buildStatCard(
              context: context,
              title: 'Suất ăn treo',
              icon: Icons.card_giftcard,
              color: Colors.orange,
              value: count.toString(),
            );
          },
        ),
        // Card 4: Suất ăn tồn trong ngay
        // Dùng StreamBuilder để kết hợp 2 stream
        // Rx.combineLatest2 sẽ phát ra giá trị mỗi khi một trong hai stream con thay đổi
        StreamBuilder<List<int>>(
          stream: Rx.combineLatest2(
            dashboardViewModel.getTodayTotalOffered(restaurant.id),
            dashboardViewModel.getTodayClaimed(restaurant.id),
              (total, claimed) => [total, claimed], // Gộp kết quả thành một List
          ),
          builder: (context,snapshot){
            int remaining = 0;
            if(snapshot.hasData && snapshot.data!.isNotEmpty){
              final total = snapshot.data![0];
              final claimed = snapshot.data![1];
              remaining = total - claimed;
              //Dam bao khong co so am
              if(remaining < 0) remaining = 0;
            }

            return _buildStatCard(
                context: context,
                title: 'Tồn trong ngày',
                icon: Icons.inventory_2_outlined,
                color: Colors.purple,
            value: snapshot.hasData? remaining.toString(): null,
              // Nếu không có giá trị, _buildStatCard sẽ tự hiển thị loadin
            );
          },
        )

      ],
    );
  }
  // Widget con để xây dựng một Card thống kê
  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    Stream<int>? stream,
    String? value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                Icon(icon, color: color),
              ],
            ),
            if (value != null)
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold))
            else
              StreamBuilder<int>(
                stream: stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  return Text(
                    snapshot.data.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}