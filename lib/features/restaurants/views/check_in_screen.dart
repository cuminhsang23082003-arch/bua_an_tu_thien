  import 'package:flutter/material.dart';
  import 'package:mobile_scanner/mobile_scanner.dart';
  import 'package:provider/provider.dart';
  import '../../beneficiary/repositories/registration_repository.dart';
  import '../models/restaurant_model.dart';

  class CheckInScreen extends StatefulWidget {
    final RestaurantModel restaurant;
    const CheckInScreen({Key? key, required this.restaurant}) : super(key: key);

    @override
    State<CheckInScreen> createState() => _CheckInScreenState();
  }

  class _CheckInScreenState extends State<CheckInScreen> with SingleTickerProviderStateMixin {
    final MobileScannerController _scannerController = MobileScannerController();
    final TextEditingController _phoneController = TextEditingController();
    late TabController _tabController;
    bool _isProcessing = false;

    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 2, vsync: this);
    }

    @override
    void dispose() {
      _scannerController.dispose();
      _phoneController.dispose();
      _tabController.dispose();
      super.dispose();
    }

    // --- LOGIC XỬ LÝ ---

    void _onQrDetect(BarcodeCapture capture) {
      if (_isProcessing) return;
      if (capture.barcodes.isNotEmpty && capture.barcodes.first.rawValue != null) {
        _processClaimId(capture.barcodes.first.rawValue!);
      }
    }

    Future<void> _processClaimId(String id) async {
      setState(() => _isProcessing = true);
      try {
        final msg = await context.read<RegistrationRepository>().claimRegistration(id);
        _showResultDialog(msg.contains('thành công'), msg);
      } catch (e) {
        _showResultDialog(false, e.toString());
      } finally {
        setState(() => _isProcessing = false);
      }
    }

    Future<void> _handlePhoneSearch() async {
      if (_phoneController.text.isEmpty) return;
      setState(() => _isProcessing = true);
      final repo = context.read<RegistrationRepository>();
      final phone = _phoneController.text.trim();

      try {
        // 1. Tìm vé đã đặt trước
        final pendingRegs = await repo.findPendingRegistrationsByPhone(phone, widget.restaurant.id);

        if (pendingRegs.isNotEmpty) {
          // Có vé -> Nhận vé đó
          _showConfirmDialog("Tìm thấy vé đặt trước", "Xác nhận trả món cho SĐT này?",
                  () => _processClaimId(pendingRegs.first.id));
        } else {
          // 2. Không có vé -> Tìm User xem có phải thành viên không
          final user = await repo.findUserByPhone(phone);
          if (user != null) {
            _showConfirmDialog("Thành viên: ${user.displayName}", "Khách chưa đặt trước. Tạo vé và nhận ngay?",
                    () async {
                  await repo.claimDirectlyForUser(widget.restaurant.id, user);
                  _showResultDialog(true, "Đã phát cơm thành công!");
                });
          } else {
            _showUnknownUserDialog();
          }
        }
      } catch (e) {
        _showResultDialog(false, "Lỗi: $e");
      } finally {
        setState(() => _isProcessing = false);
      }
    }

    Future<void> _handleWalkIn() async {
      _showConfirmDialog("Khách vãng lai", "Phát 1 suất cho người không có tài khoản?", () async {
        setState(() => _isProcessing = true);
        try {
          await context.read<RegistrationRepository>().claimForWalkInGuest(widget.restaurant.id);
          _showResultDialog(true, "Đã phát cơm thành công!");
        } catch (e) {
          _showResultDialog(false, e.toString());
        } finally {
          setState(() => _isProcessing = false);
        }
      });
    }

    // --- UI DIALOGS ---

    void _showResultDialog(bool success, String msg) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Icon(success ? Icons.check_circle : Icons.error, color: success ? Colors.green : Colors.red, size: 50),
        content: Text(msg, textAlign: TextAlign.center),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ));
    }

    void _showConfirmDialog(String title, String content, VoidCallback onConfirm) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(title), content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); onConfirm(); }, child: const Text("Đồng ý")),
        ],
      ));
    }

    void _showUnknownUserDialog() {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text("SĐT chưa đăng ký"),
        content: const Text("Số này chưa có trong hệ thống. Bạn có muốn phát theo diện 'Khách vãng lai'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); _handleWalkIn(); }, child: const Text("Phát vãng lai")),
        ],
      ));
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trả món / Check-in'),
          bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "Quét QR"), Tab(text: "Nhập SĐT")]),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: QR
            Stack(children: [
              MobileScanner(controller: _scannerController, onDetect: _onQrDetect),
              Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 3), borderRadius: BorderRadius.circular(12)))),
            ]),
            // Tab 2: Manual
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text("Dành cho khách không dùng App", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController, keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: "Nhập SĐT người nhận", border: const OutlineInputBorder(), suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _handlePhoneSearch)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _handlePhoneSearch, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("Tìm kiếm & Phát món")),
                    const Divider(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(children: [
                        const Text("Khách vãng lai / Vô gia cư", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _handleWalkIn, icon: const Icon(Icons.person_add), label: const Text("Phát 1 suất ngay"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white)))
                      ]),
                    )
                  ]),
                ),
              ),
            )
          ],
        ),
      );
    }
  }