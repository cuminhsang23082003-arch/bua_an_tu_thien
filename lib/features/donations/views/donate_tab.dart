// lib/features/donations/views/donate_tab.dart
import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/donations/models/donation_model.dart';
import 'package:buaanyeuthuong/features/donations/viewmodels/donation_viewmodel.dart';
import 'package:buaanyeuthuong/features/restaurants/models/restaurant_model.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DonateTab extends StatelessWidget {
  const DonateTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final restaurantRepo = context.read<RestaurantRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Quyên góp & Hỗ trợ')),
      body: FutureBuilder<List<RestaurantModel>>(
        future: restaurantRepo.getAllActiveRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Không có quán ăn nào để quyên góp.'),
            );
          }
          final restaurants = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              return _buildRestaurantCard(context, restaurants[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    RestaurantModel restaurant,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          child: restaurant.imageUrl != null
              ? ClipOval(
                  child: Image.network(
                    restaurant.imageUrl!,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  ),
                )
              : const Icon(Icons.storefront),
        ),
        title: Text(
          restaurant.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${restaurant.district}, ${restaurant.province}\nĐang có: ${restaurant.suspendedMealsCount} suất ăn treo',
        ),
        isThreeLine: true,
        trailing: ElevatedButton(
          onPressed: () => _showDonateDialog(context, restaurant),
          child: const Text('Quyên góp'),
        ),
      ),
    );
  }

  void _showDonateDialog(BuildContext context, RestaurantModel restaurant) {
    showDialog(
      context: context,
      builder: (ctx) =>
          DonateDialog(restaurant: restaurant), // Gọi Dialog riêng
    );
  }
}

// Tách Dialog ra một StatefulWidget riêng để quản lý State
class DonateDialog extends StatefulWidget {
  final RestaurantModel restaurant;

  const DonateDialog({Key? key, required this.restaurant}) : super(key: key);

  @override
  State<DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<DonateDialog> {
  final _formKey = GlobalKey<FormState>();
  DonationType _selectedType = DonationType.suspended_meal;

  // Controllers cho các loại quyên góp
  final _quantityController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _unitController = TextEditingController();
  final _amountController = TextEditingController();

  static const double _giaTienMoiSuatAnTreo = 25000;
  final _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  String _tongGiaTienText = '';

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_updateTotalAmount);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_updateTotalAmount);
    _itemNameController.dispose();
    _unitController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateTotalAmount() {
    if (_selectedType == DonationType.suspended_meal) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      if (quantity > 0) {
        final total = quantity * _giaTienMoiSuatAnTreo;
        setState(() {
          _tongGiaTienText = 'Tổng tiền: ${_currencyFormatter.format(total)}';
        });
      } else {
        setState(() {
          _tongGiaTienText = '';
        });
      }
    }
  }

  // Hàm xây dựng Form dựa trên loại quyên góp được chọn
  Widget _buildDonationForm() {
    switch (_selectedType) {
      case DonationType.suspended_meal:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Số lượng suất ăn'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (v == null || v.isEmpty || int.parse(v) <= 0)
                  ? 'Số lượng không hợp lệ'
                  : null,
            ),

            if(_tongGiaTienText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_tongGiaTienText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),

          ],
        );

      case DonationType.material:
        return Column(
          children: [
            TextFormField(
              controller: _itemNameController,
              decoration: const InputDecoration(
                labelText: 'Tên vật phẩm (Gạo, rau...)',
              ),
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.isEmpty || int.parse(v) <= 0)
                        ? 'Vui lòng nhập'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị (kg, thùng...)',
                    ),
                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
                  ),
                ),
              ],
            ),
          ],
        );
      case DonationType.cash:
        return TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => (v == null || v.isEmpty || double.parse(v) <= 0)
              ? 'Số tiền không hợp lệ'
              : null,
        );
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    final donor = context.read<AuthViewModel>().currentUser;
    if (donor == null) return;

    // Tạo đối tượng DonationModel dựa trên dữ liệu đã nhập
    final donation = DonationModel(
      id: '',
      // Sẽ được tạo trong repository
      donorUid: donor.uid,
      targetRestaurantId: widget.restaurant.id,
      targetRestaurantName: widget.restaurant.name,
      type: _selectedType,
      donatedAt: Timestamp.now(),
      quantity: int.tryParse(_quantityController.text),
      itemName: _itemNameController.text.trim().isEmpty
          ? null
          : _itemNameController.text.trim(),
      unit: _unitController.text.trim().isEmpty
          ? null
          : _unitController.text.trim(),
      amount: double.tryParse(_amountController.text),
      currency: _selectedType == DonationType.cash ? 'VND' : null,
    );

    final viewModel = context.read<DonationViewModel>();
    final error = await viewModel.makeDonation(donation);

    if (mounted) {
      Navigator.of(context).pop();
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quyên góp thành công! Cảm ơn tấm lòng của bạn.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Quyên góp cho ${widget.restaurant.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade800),
                    children: [
                      const WidgetSpan(child: Icon(Icons.info_outline, color: Colors.blue, size: 16), alignment: PlaceholderAlignment.middle),
                      const TextSpan(text: ' Lưu ý: Vui lòng liên hệ và thanh toán trực tiếp với quán qua SĐT: '),
                      TextSpan(text: widget.restaurant.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),


              // Dropdown chọn loại quyên góp
              DropdownButtonFormField<DonationType>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(
                    value: DonationType.suspended_meal,
                    child: Text('Suất ăn treo'),
                  ),
                  DropdownMenuItem(
                    value: DonationType.material,
                    child: Text('Vật phẩm'),
                  ),
                  DropdownMenuItem(
                    value: DonationType.cash,
                    child: Text('Tiền'),
                  ),
                ],
                onChanged: (type) {
                  if (type != null)
                    setState(() {
                      _selectedType = type;
                    });
                },
                decoration: const InputDecoration(
                  labelText: 'Hình thức quyên góp',
                ),
              ),
              const SizedBox(height: 16),
              // Form động
              _buildDonationForm(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        Consumer<DonationViewModel>(
          builder: (context, viewModel, child) {
            return viewModel.isDonating
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                : ElevatedButton(
                    onPressed: _submitDonation,
                    child: const Text('Xác nhận'),
                  );
          },
        ),
      ],
    );
  }
}
