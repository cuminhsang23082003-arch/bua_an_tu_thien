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
      backgroundColor: Colors.grey.shade50, // Màu nền hiện đại
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Tất cả suất ăn', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort, color: Colors.orange),
            tooltip: 'Sắp xếp',
            onSelected: (SortOption result) {
              setState(() { _sortOption = result; });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(value: SortOption.byDate, child: Text('Ngày gần nhất')),
              const PopupMenuItem<SortOption>(value: SortOption.byRemaining, child: Text('Số suất còn lại')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: StreamBuilder<List<MealEventModel>>(
              stream: mealEventRepo.getAllActiveMealEventsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải dữ liệu', style: TextStyle(color: Colors.grey.shade600)));
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Không tìm thấy suất ăn phù hợp', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: processedEvents.length,
                  separatorBuilder: (ctx, index) => const SizedBox(height: 12),
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

  // --- UI: KHỐI TÌM KIẾM & LỌC ---
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Thanh tìm kiếm
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm món ăn, quán...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchController.clear())
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Hàng Dropdown
          Row(
            children: [
              Expanded(
                child: _buildDropdown<Province>(
                  value: _selectedProvince,
                  hint: _isLoadingProvinces ? 'Đang tải...' : 'Tỉnh/TP',
                  items: _provinces,
                  displayFunc: (p) => p.name,
                  onChanged: (Province? newValue) {
                    setState(() {
                      _selectedProvince = newValue;
                      _selectedDistrict = null;
                      _districts = [];
                    });
                    if (newValue != null) _loadDistrictsForFilter(newValue.code);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown<District>(
                  value: _selectedDistrict,
                  hint: _isLoadingDistricts ? 'Đang tải...' : 'Quận/Huyện',
                  items: _districts,
                  displayFunc: (d) => d.name,
                  enabled: _selectedProvince != null,
                  onChanged: (District? newValue) => setState(() => _selectedDistrict = newValue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) displayFunc,
    required Function(T?)? onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(displayFunc(item), style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  // --- UI: CARD SỰ KIỆN ---
  Widget _buildEventCard(BuildContext context, MealEventModel event) {
    final date = event.eventDate.toDate();
    final isAvailable = event.remainingMeals > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealEventDetailScreen(mealEvent: event))),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khối ngày tháng (Calendar Box)
                Container(
                  width: 50,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('dd').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
                      Text(DateFormat('MM').format(date), style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Thông tin chính
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(event.restaurantName, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text('${event.district}, ${event.province}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Badge & Thông tin còn lại
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAvailable ? 'Còn ${event.remainingMeals} suất' : 'Hết suất',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAvailable ? Colors.green : Colors.red),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('${event.startTime} - ${event.endTime}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      // Suất ăn treo (Async Widget)
                      _buildSuspendedMealsBadge(context, event.restaurantId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuspendedMealsBadge(BuildContext context, String restaurantId) {
    return FutureBuilder<RestaurantModel?>(
      future: context.read<RestaurantRepository>().getRestaurantById(restaurantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.suspendedMealsCount == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard, size: 12, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'Có ${snapshot.data!.suspendedMealsCount} suất treo miễn phí',
                style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }
}