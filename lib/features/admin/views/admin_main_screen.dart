// lib/features/admin/views/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../authentication/viewmodels/auth_viewmodel.dart';
import '../repositories/admin_repository.dart';
import '../../authentication/models/user_model.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../../donations/models/donation_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final adminRepo = context.read<AdminRepository>();

    final List<Widget> _pages = [
      _DashboardPage(repo: adminRepo),
      _RestaurantManagementPage(repo: adminRepo),
      _UserManagementPage(repo: adminRepo),
      _DonationAuditPage(repo: adminRepo),
    ];

    final _titles = [
      'Tổng quan hệ thống',
      'Quản lý tài khoản quán ăn',
      'Quản lý tài khoản người dùng',
      'Quản lý giao dịch quyên góp'
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueGrey),
              accountName: const Text("ADMINISTRATOR", style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text("Control Panel"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.blueGrey),
              ),
            ),
            _buildNavItem(0, 'Tổng quan hệ thống', Icons.dashboard),
            _buildNavItem(1, 'Quản lý tài khoản quán ăn', Icons.store),
            _buildNavItem(2, 'Quản lý tài khoản người dùng', Icons.people),
            _buildNavItem(3, 'Quản lý giao dịch quyên góp', Icons.volunteer_activism),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () => context.read<AuthViewModel>().signOut(),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Colors.blueGrey : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          color: _selectedIndex == index ? Colors.blueGrey : Colors.black87,
        ),
      ),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.blueGrey.withOpacity(0.1),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

// --- TRANG 1: DASHBOARD ---
class _DashboardPage extends StatelessWidget {
  final AdminRepository repo;
  const _DashboardPage({required this.repo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: repo.getSystemStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? {'users': 0, 'restaurants': 0, 'donations': 0, 'meals': 0};

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard('Người dùng', '${data['users']}', Icons.people, Colors.blue),
              _buildStatCard('Quán ăn', '${data['restaurants']}', Icons.store, Colors.orange),
              _buildStatCard('Lượt quyên góp', '${data['donations']}', Icons.favorite, Colors.red),
              _buildStatCard('Đợt phát ăn', '${data['meals']}', Icons.rice_bowl, Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// --- TRANG 2: QUẢN LÝ QUÁN (ĐÃ SỬA LOGIC DUYỆT/TỪ CHỐI/KHÓA) ---
class _RestaurantManagementPage extends StatefulWidget {
  final AdminRepository repo;
  const _RestaurantManagementPage({required this.repo});

  @override
  State<_RestaurantManagementPage> createState() => _RestaurantManagementPageState();
}

class _RestaurantManagementPageState extends State<_RestaurantManagementPage> {
  // 0: Tất cả, 1: Chờ duyệt, 2: Hoạt động, 3: Đã khóa
  int _filterStatus = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RestaurantModel>>(
      stream: widget.repo.getAllRestaurantsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final allRestaurants = snapshot.data!;

        // 1. Đã khóa (Banned)
        final bannedList = allRestaurants.where((r) => r.isBanned).toList();
        // 2. Chờ duyệt (Pending: Chưa Verified & Chưa Ban)
        final pendingList = allRestaurants.where((r) => !r.isVerified && !r.isBanned).toList();
        // 3. Hoạt động (Active: Đã Verified & Chưa Ban)
        final activeList = allRestaurants.where((r) => r.isVerified && !r.isBanned).toList();

        List<RestaurantModel> displayList;
        if (_filterStatus == 1) displayList = pendingList;
        else if (_filterStatus == 2) displayList = activeList;
        else if (_filterStatus == 3) displayList = bannedList;
        else displayList = allRestaurants;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterCard(0, 'Tất cả', allRestaurants.length, Colors.blueGrey),
                  _buildFilterCard(1, 'Chờ duyệt', pendingList.length, Colors.orange),
                  _buildFilterCard(2, 'Hoạt động', activeList.length, Colors.green),
                  _buildFilterCard(3, 'Đã khóa', bannedList.length, Colors.red),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: displayList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    const Text("Danh sách trống", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final r = displayList[index];
                  return _buildRestaurantItem(r, widget.repo);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterCard(int index, String label, int count, Color color) {
    final isSelected = _filterStatus == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 2 : 1
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: isSelected ? color : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ITEM LIST ---
  Widget _buildRestaurantItem(RestaurantModel r, AdminRepository repo) {
    return Card(
      color: r.isBanned ? Colors.red.shade50 : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () => _showRestaurantDetail(context, r),
        leading: CircleAvatar(
          backgroundColor: r.isBanned
              ? Colors.red
              : (r.isVerified ? Colors.green : Colors.orange),
          child: Icon(
              r.isBanned ? Icons.lock : (r.isVerified ? Icons.check : Icons.hourglass_top),
              color: Colors.white
          ),
        ),
        title: Text(
          r.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.phoneNumber),
            Text(
              r.address,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'verify') repo.updateRestaurantStatus(r.id, isVerified: true);
            if (value == 'reject') _confirmReject(context, r, repo); // Từ chối -> Xóa
            if (value == 'ban') repo.updateRestaurantStatus(r.id, isBanned: true);
            if (value == 'unban') repo.updateRestaurantStatus(r.id, isBanned: false);
          },
          itemBuilder: (context) {
            // [LOGIC MENU ĐƯỢC PHÂN TÁCH RÕ RÀNG]

            // 1. Nếu đang CHỜ DUYỆT -> Chỉ hiện Duyệt / Từ chối
            if (!r.isVerified && !r.isBanned) {
              return [
                const PopupMenuItem(
                  value: 'verify',
                  child: Row(children: [Icon(Icons.check, color: Colors.green), SizedBox(width: 8), Text('Duyệt quán')]),
                ),
                const PopupMenuItem(
                  value: 'reject',
                  child: Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 8), Text('Từ chối')]),
                ),
              ];
            }

            // 2. Nếu đã KHÓA -> Chỉ hiện Mở khóa
            if (r.isBanned) {
              return [
                const PopupMenuItem(
                  value: 'unban',
                  child: Row(children: [Icon(Icons.lock_open, color: Colors.green), SizedBox(width: 8), Text('Mở khóa')]),
                ),
              ];
            }

            // 3. Nếu đang HOẠT ĐỘNG -> Chỉ hiện Khóa
            return [
              const PopupMenuItem(
                value: 'ban',
                child: Row(children: [Icon(Icons.lock, color: Colors.red), SizedBox(width: 8), Text('Khóa quán')]),
              ),
            ];
          },
        ),
      ),
    );
  }

  // Hộp thoại xác nhận từ chối
  void _confirmReject(BuildContext context, RestaurantModel r, AdminRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Từ chối hồ sơ?"),
        content: const Text("Hành động này sẽ xóa hoàn toàn hồ sơ quán ăn này khỏi hệ thống. Bạn có chắc chắn không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              repo.deleteRestaurant(r.id); // Gọi hàm xóa trong Repo
              Navigator.pop(ctx);
            },
            child: const Text("Xác nhận từ chối", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- BOTTOM SHEET CHI TIẾT ---
  void _showRestaurantDetail(BuildContext context, RestaurantModel r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (_, controller) => SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 200, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        image: r.imageUrl != null ? DecorationImage(image: NetworkImage(r.imageUrl!), fit: BoxFit.cover) : null,
                      ),
                      child: r.imageUrl == null ? const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)) : null,
                    ),
                    Positioned(
                      top: 10, right: 10,
                      child: IconButton(
                        icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.close, color: Colors.black)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(r.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                          _buildStatusBadge(r),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(children: [const Icon(Icons.person, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(r.ownerName, style: const TextStyle(fontSize: 16, color: Colors.grey))]),
                      Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(r.phoneNumber, style: const TextStyle(fontSize: 16, color: Colors.grey))]),
          
                      const Divider(height: 30),
                      _buildDetailRow(Icons.location_on, 'Địa chỉ', '${r.address}, ${r.district}, ${r.province}'),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.description, 'Mô tả', r.description),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.access_time, 'Giờ hoạt động', _formatOperatingHours(r.operatingHours)),
                      const SizedBox(height: 30),
          
                      // [CÁC NÚT HÀNH ĐỘNG] - ĐƯỢC PHÂN TÁCH RÕ RÀNG
          
                      // TRƯỜNG HỢP 1: CHỜ DUYỆT (Hiện nút Từ chối & Duyệt)
                      if (!r.isVerified && !r.isBanned) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _confirmReject(context, r, widget.repo);
                                },
                                icon: const Icon(Icons.close), label: const Text("TỪ CHỐI"),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  widget.repo.updateRestaurantStatus(r.id, isVerified: true);
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.check), label: const Text("DUYỆT NGAY"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ),
                          ],
                        )
          
                        // TRƯỜNG HỢP 2: ĐÃ KHÓA (Hiện nút Mở khóa)
                      ] else if (r.isBanned) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              widget.repo.updateRestaurantStatus(r.id, isBanned: false);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.lock_open), label: const Text("MỞ KHÓA TÀI KHOẢN"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        )
          
                        // TRƯỜNG HỢP 3: ĐANG HOẠT ĐỘNG (Hiện nút Khóa)
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              widget.repo.updateRestaurantStatus(r.id, isBanned: true);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.lock), label: const Text("KHÓA QUÁN ĂN"),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        )
                      ]
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

  Widget _buildStatusBadge(RestaurantModel r) {
    if (r.isBanned) {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('Đã khóa', style: TextStyle(color: Colors.white, fontSize: 12)));
    }
    if (r.isVerified) {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)), child: const Text('Hoạt động', style: TextStyle(color: Colors.white, fontSize: 12)));
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: const Text('Chờ duyệt', style: TextStyle(color: Colors.white, fontSize: 12)));
  }

  Widget _buildDetailRow(IconData icon, String title, String content) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: Colors.blueGrey), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(content, style: const TextStyle(color: Colors.black87, height: 1.4))]))]);
  }

  String _formatOperatingHours(Map<String, String> hours) {
    if (hours.isEmpty) return "Chưa cập nhật";
    return hours.entries.map((e) => "${e.key}: ${e.value}").join('\n');
  }
}

// --- TRANG 3: QUẢN LÝ USER ---
class _UserManagementPage extends StatefulWidget {
  final AdminRepository repo;
  const _UserManagementPage({required this.repo});

  @override
  State<_UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<_UserManagementPage> {
  int _filterStatus = 0; // 0: All, 1: Active, 2: Banned

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: widget.repo.getAllUsersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final allUsers = snapshot.data!;

        final activeUsers = allUsers.where((u) => u.isActive).toList();
        final bannedUsers = allUsers.where((u) => !u.isActive).toList();

        List<UserModel> displayList;
        if (_filterStatus == 1) displayList = activeUsers;
        else if (_filterStatus == 2) displayList = bannedUsers;
        else displayList = allUsers;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  _buildFilterCard(0, 'Tất cả', allUsers.length, Colors.blueGrey),
                  _buildFilterCard(1, 'Hoạt động', activeUsers.length, Colors.green),
                  _buildFilterCard(2, 'Đã khóa', bannedUsers.length, Colors.red),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: displayList.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70),
                itemBuilder: (context, index) {
                  final u = displayList[index];
                  return ListTile(
                    tileColor: u.isActive ? null : Colors.red.shade50,
                    leading: CircleAvatar(
                      backgroundColor: u.role == UserRole.admin ? Colors.red : (u.isActive ? Colors.blue : Colors.grey),
                      child: Text(u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(u.displayName, style: TextStyle(decoration: !u.isActive ? TextDecoration.lineThrough : null)),
                    subtitle: Text(
                      '${u.phoneNumber ?? u.email}\n${u.role.displayName}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: u.role == UserRole.admin
                        ? null
                        : Switch(
                      value: u.isActive,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                      onChanged: (val) {
                        widget.repo.toggleUserBan(u.uid, u.isActive);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterCard(int index, String label, int count, Color color) {
    final isSelected = _filterStatus == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 2 : 1
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey.shade700)),
              Text(label, style: TextStyle(fontSize: 11, color: isSelected ? color : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- TRANG 4: SỔ CÁI (Giữ nguyên) ---
class _DonationAuditPage extends StatelessWidget {
  final AdminRepository repo;
  const _DonationAuditPage({required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DonationModel>>(
      stream: repo.getAllDonationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final donations = snapshot.data!;
        final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        return ListView.builder(
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final d = donations[index];
            String amountDisplay = '';
            IconData icon = Icons.help;
            Color color = Colors.grey;

            if (d.type == DonationType.cash) {
              amountDisplay = currencyFormat.format(d.amount ?? 0);
              icon = Icons.attach_money;
              color = Colors.green;
            } else if (d.type == DonationType.suspended_meal) {
              amountDisplay = '${d.quantity} suất';
              icon = Icons.rice_bowl;
              color = Colors.orange;
            } else {
              amountDisplay = '${d.quantity} ${d.unit} ${d.itemName}';
              icon = Icons.inventory_2;
              color = Colors.purple;
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color),
                ),
                title: Text('Đến: ${d.targetRestaurantName}'),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(d.donatedAt.toDate())),
                trailing: Text(amountDisplay, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
              ),
            );
          },
        );
      },
    );
  }
}