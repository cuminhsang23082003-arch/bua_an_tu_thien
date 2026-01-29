import 'package:buaanyeuthuong/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:buaanyeuthuong/features/dashboard/views/detailed_report_list_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../restaurants/models/restaurant_model.dart';

enum TimeRange { week, month, allTime }

class ReportsScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const ReportsScreen({Key? key, required this.restaurant}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  TimeRange _selectedRange = TimeRange.week;
  Future<Map<String, num>>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<DashboardViewModel>();
      setState(() {
        _statsFuture = viewModel.getReportStats(
          widget.restaurant.id,
          _selectedRange,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo & Thống kê')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<TimeRange>(
              segments: const [
                ButtonSegment(value: TimeRange.week, label: Text('Tuần này')),
                ButtonSegment(value: TimeRange.month, label: Text('Tháng này')),
                ButtonSegment(
                  value: TimeRange.allTime,
                  label: Text('Toàn thời gian'),
                ),
              ],
              selected: {_selectedRange},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedRange = newSelection.first;
                });
                _loadStats();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, num>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi tải báo cáo.'));
                }

                final stats = snapshot.data ?? {};
                final claimedMeals = stats['claimedMeals'] ?? 0;
                final donatedSuspendedMeals =
                    stats['donatedSuspendedMeals'] ?? 0;
                final createdEvents = stats['createdEvents'] ?? 0;
                final donatedMaterials = stats['donatedMaterials'] ?? 0;
                final donatedCash = stats['donatedCash'] ?? 0.0;

                final currencyFormatter = NumberFormat.currency(
                  locale: 'vi_VN',
                  symbol: 'đ',
                );

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // [SỬA ĐỔI] Thêm onTap
                    _buildReportCard(
                      title: 'Tổng suất ăn đã phát',
                      value: claimedMeals.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onTap: () => _navigateToDetail(
                        context,
                        'claimedMeals',
                        'Chi tiết suất ăn đã phát',
                      ),
                    ),
                    _buildReportCard(
                      title: 'Suất ăn treo được quyên góp',
                      value: donatedSuspendedMeals.toString(),
                      icon: Icons.volunteer_activism,
                      color: Colors.orange,
                      onTap: () => _navigateToDetail(
                        context,
                        'donatedSuspendedMeals',
                        'Chi tiết suất ăn treo được tặng',
                      ),
                    ),
                    _buildReportCard(
                      title: 'Đợt phát ăn đã tạo',
                      value: createdEvents.toString(),
                      icon: Icons.event_note,
                      color: Colors.blue,
                    ),

                    _buildReportCard(
                      title: 'Nguyên vật liệu được quyên góp',
                      value: donatedMaterials.toString(),
                      icon: Icons.inventory,
                      color: Colors.brown,
                      onTap: () => _navigateToDetail(
                        context,
                        'donatedMaterials',
                        'Chi tiết nguyên vật liệu được quyên góp',
                      ),
                    ),
                    _buildReportCard(
                      title: 'Tổng tiền được quyên góp',
                      value: currencyFormatter.format(donatedCash),
                      icon: Icons.monetization_on,
                      color: Colors.teal,
                      onTap: () => _navigateToDetail(
                        context,
                        'donatedCash',
                        'Chi tiết số tiền quyên góp',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(
    BuildContext context,
    String reportType,
    String title,
  ) {
    final viewModel = context.read<DashboardViewModel>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailedReportListScreen(
          title: title,
          itemsStream: viewModel.getDetailedReportStream(
            reportType: reportType,
            restaurantId: widget.restaurant.id,
            range: _selectedRange,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.black54)),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
