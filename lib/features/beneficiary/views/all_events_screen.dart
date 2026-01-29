// lib/features/beneficiary/views/all_events_screen.dart
import 'package:buaanyeuthuong/features/core/repositories/address_repository.dart';
import 'package:buaanyeuthuong/features/beneficiary/views/meal_detail_screen.dart';
import 'package:buaanyeuthuong/features/meal_events/models/meal_event_model.dart';
import 'package:buaanyeuthuong/features/meal_events/repositories/meal_event_repository.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


enum SortOption { byDate, byRemaining }

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({Key? key}) : super(key: key);

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  Province? _selectedProvince;
  District? _selectedDistrict;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _sortOption = SortOption.byDate;

  final AddressRepository _addressRepository = AddressRepository();
  List<Province> _provinces = [];
  List<District> _districts = [];
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() { _searchQuery = _searchController.text; });
    });
    _loadProvincesForFilter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProvincesForFilter() async {
    setState(() { _isLoadingProvinces = true; });
    try {
      var provinces = await _addressRepository.getProvinces();
      if (mounted) setState(() { _provinces = provinces; });
    } catch (e) { print(e); } finally {
      if (mounted) setState(() { _isLoadingProvinces = false; });
    }
  }

  Future<void> _loadDistrictsForFilter(int provinceCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _selectedDistrict = null;
    });
    try {
      var districts = await _addressRepository.getDistricts(provinceCode);
      if (mounted) setState(() { _districts = districts; });
    } catch (e) { print(e); } finally {
      if (mounted) setState(() { _isLoadingDistricts = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealEventRepo = context.read<MealEventRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả suất ăn'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            onSelected: (SortOption result) {
              setState(() { _sortOption = result; });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(value: SortOption.byDate, child: Text('Theo ngày gần nhất')),
              const PopupMenuItem<SortOption>(value: SortOption.byRemaining, child: Text('Theo số suất còn lại')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<MealEventModel>>(
              stream: mealEventRepo.getAllActiveMealEventsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("Lỗi StreamBuilder: ${snapshot.error}");
                  return const Center(child: Text('Đã có lỗi xảy ra.'));
                }

                final allEvents = snapshot.data ?? [];
                var processedEvents = allEvents.where((event) {
                  final status = event.effectiveStatus;
                  final isStatusValid = status == MealEventStatus.scheduled || status == MealEventStatus.ongoing;
                  final isProvinceMatch = _selectedProvince == null || event.province == _selectedProvince!.name;
                  final isDistrictMatch = _selectedDistrict == null || event.district == _selectedDistrict!.name;
                  final isSearchMatch = _searchQuery.isEmpty ||
                      event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      event.restaurantName.toLowerCase().contains(_searchQuery.toLowerCase());
                  return isStatusValid && isProvinceMatch && isDistrictMatch && isSearchMatch;
                }).toList();

                processedEvents.sort((a, b) {
                  if (_sortOption == SortOption.byRemaining) {
                    return b.remainingMeals.compareTo(a.remainingMeals);
                  } else {
                    return a.eventDate.compareTo(b.eventDate);
                  }
                });

                if (processedEvents.isEmpty) {
                  return const Center(child: Text('Không có suất ăn nào phù hợp.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: processedEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(context, processedEvents[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // [ĐẦY ĐỦ] Widget xây dựng giao diện bộ lọc ĐỘNG
  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo món ăn, tên quán...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Province>(
                  value: _selectedProvince,
                  hint: _isLoadingProvinces ? const Text('Đang tải...') : const Text('Tất cả Tỉnh/TP'),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                  items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (Province? newValue) {
                    setState(() {
                      _selectedProvince = newValue;
                      _selectedDistrict = null;
                      _districts = [];
                    });
                    if (newValue != null) {
                      _loadDistrictsForFilter(newValue.code);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<District>(
                  value: _selectedDistrict,
                  hint: _selectedProvince == null
                      ? const Text('Chọn tỉnh trước')
                      : (_isLoadingDistricts
                      ? const Text('Đang tải...')
                      : const Text('Tất cả Quận/Huyện')),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                  items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: _selectedProvince == null ? null : (District? newValue) {
                    setState(() {
                      _selectedDistrict = newValue;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // [ĐẦY ĐỦ] Widget cho một Card hiển thị thông tin đợt phát ăn
  Widget _buildEventCard(BuildContext context, MealEventModel event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealEventDetailScreen(mealEvent: event)));
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Tại: ${event.restaurantName}', style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
              const Divider(height: 20),
              _buildInfoRow(Icons.pin_drop_outlined, '${event.district}, ${event.province}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.calendar_today_outlined, DateFormat('dd/MM/yyyy').format(event.eventDate.toDate())),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.access_time_outlined, '${event.startTime} - ${event.endTime}'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.restaurant_menu_outlined, 'Còn lại ${event.remainingMeals} suất'),
              _buildSuspendedMealsInfo(context, event.restaurantId),
            ],
          ),
        ),
      ),
    );
  }

  // [ĐẦY ĐỦ] Widget con để hiển thị một dòng thông tin
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 15))),
      ],
    );
  }

  // [ĐẦY ĐỦ] Widget con để tải và hiển thị thông tin suất ăn treo
  Widget _buildSuspendedMealsInfo(BuildContext context, String restaurantId) {
    final restaurantRepo = context.read<RestaurantRepository>();
    return FutureBuilder<RestaurantModel?>(
      future: restaurantRepo.getRestaurantById(restaurantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.suspendedMealsCount == 0) {
          return const SizedBox.shrink();
        }
        final count = snapshot.data!.suspendedMealsCount;
        return Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: _buildInfoRow(Icons.card_giftcard, 'Có $count suất ăn treo'),
        );
      },
    );
  }
}