// lib/features/beneficiary/views/beneficiary_dashboard.dart
import 'package:buaanyeuthuong/features/beneficiary/views/home_tab.dart';
import 'package:buaanyeuthuong/features/beneficiary/views/my_registrations_tab.dart';
import 'package:flutter/material.dart';
import 'package:buaanyeuthuong/features/beneficiary/views/profile_tab.dart';
import 'package:buaanyeuthuong/features/beneficiary/views/map_tab.dart';

import '../../donations/views/donate_tab.dart';

class BeneficiaryDashboard extends StatefulWidget {
  const BeneficiaryDashboard({Key? key}) : super(key: key);

  @override
  State<BeneficiaryDashboard> createState() => _BeneficiaryDashboardState();
}

class _BeneficiaryDashboardState extends State<BeneficiaryDashboard> {
  int _selectedIndex = 0;

  // Danh sách các màn hình (tab)
  static final List<Widget> _pages = <Widget>[
    // Tạm thời dùng Placeholder
    const HomeTab(),
    const MapTab(),
    const DonateTab(),
    const MyRegistrationsTab(),
    const ProfileTab()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Bản đồ'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism_outlined), label: 'Quyên góp'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFFF6B6B),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}