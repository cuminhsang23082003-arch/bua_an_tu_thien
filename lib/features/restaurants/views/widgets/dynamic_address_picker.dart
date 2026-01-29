// lib/features/restaurants/views/widgets/dynamic_address_picker.dart
import 'package:flutter/material.dart';

import '../../../core/repositories/address_repository.dart';

class DynamicAddressPicker extends StatefulWidget {
  final Function(String? province, String? district) onAddressChanged;

  // Optional: callback trả thêm code để lưu trữ ổn định hơn
  final void Function({
  String? province,
  int? provinceCode,
  String? district,
  int? districtCode,
  })? onChangedWithCode;

  final String? initialProvince;
  final String? initialDistrict;

  const DynamicAddressPicker({
    Key? key,
    required this.onAddressChanged,
    this.onChangedWithCode,
    this.initialProvince,
    this.initialDistrict,
  }) : super(key: key);

  @override
  State<DynamicAddressPicker> createState() => _DynamicAddressPickerState();
}

class _DynamicAddressPickerState extends State<DynamicAddressPicker> {
  final AddressRepository _addressRepository = AddressRepository();

  List<Province> _provinces = [];
  List<District> _districts = [];
  Province? _selectedProvince;
  District? _selectedDistrict;

  bool _isLoadingProvinces = true;
  bool _isLoadingDistricts = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  String _canonicalize(String? s) {
    if (s == null) return '';
    var x = s.toLowerCase().trim();
    x = x.replaceAll(RegExp(r'^(thành phố|tp\.?)\s+'), '');
    x = x.replaceAll(RegExp(r'^tỉnh\s+'), '');
    x = x.replaceAll(RegExp(r'\s+'), ' ');
    return x;
  }

  Future<void> _loadProvinces() async {
    if (mounted) setState(() => _isLoadingProvinces = true);
    try {
      final provinces = await _addressRepository.getProvinces();
      Province? initialProvince;
      if (widget.initialProvince != null) {
        final target = _canonicalize(widget.initialProvince);
        try {
          initialProvince = provinces.firstWhere(
                (p) => _canonicalize(p.name) == target,
          );
        } catch (_) {
          initialProvince = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _selectedProvince = initialProvince;
      });
      if (_selectedProvince != null) {
        await _loadDistricts(_selectedProvince!.code, isInitialLoad: true);
      }
    } catch (e) {
      // Có thể hiển thị SnackBar nếu muốn
      debugPrint('Lỗi khi lấy Tỉnh: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _loadDistricts(int provinceCode, {bool isInitialLoad = false}) async {
    if (mounted) {
      setState(() {
        _isLoadingDistricts = true;
        _districts = [];
        if (!isInitialLoad) {
          _selectedDistrict = null;
          widget.onAddressChanged(_selectedProvince?.name, null);
          widget.onChangedWithCode?.call(
            province: _selectedProvince?.name,
            provinceCode: _selectedProvince?.code,
            district: null,
            districtCode: null,
          );
        }
      });
    }
    try {
      final districts = await _addressRepository.getDistricts(provinceCode);
      District? initialDistrict;
      if (isInitialLoad && widget.initialDistrict != null) {
        final target = _canonicalize(widget.initialDistrict);
        try {
          initialDistrict = districts.firstWhere(
                (d) => _canonicalize(d.name) == target,
          );
        } catch (_) {
          debugPrint('Không tìm được Quận/Huyện: ${widget.initialDistrict}');
          initialDistrict = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _selectedDistrict = initialDistrict;
      });
    } catch (e) {
      debugPrint('Lỗi khi lấy Quận/Huyện: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<Province>(
          value: _selectedProvince,
          isExpanded: true,
          hint: _isLoadingProvinces
              ? const Text('Đang tải...')
              : const Text('Chọn Tỉnh/Thành phố'),
          decoration: const InputDecoration(
            labelText: 'Tỉnh/Thành phố',
            border: OutlineInputBorder(),
          ),
          items: _provinces.map((Province province) {
            return DropdownMenuItem<Province>(
              value: province,
              child: Text(province.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (Province? newValue) {
            setState(() {
              _selectedProvince = newValue;
            });
            if (newValue != null) {
              _loadDistricts(newValue.code);
              widget.onAddressChanged(newValue.name, null);
              widget.onChangedWithCode?.call(
                province: newValue.name,
                provinceCode: newValue.code,
                district: null,
                districtCode: null,
              );
            } else {
              setState(() {
                _districts = [];
                _selectedDistrict = null;
              });
              widget.onAddressChanged(null, null);
              widget.onChangedWithCode?.call(
                province: null,
                provinceCode: null,
                district: null,
                districtCode: null,
              );
            }
          },
          validator: (value) => value == null ? 'Vui lòng chọn Tỉnh/Thành phố' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<District>(
          value: _selectedDistrict,
          isExpanded: true,
          hint: const Text('Chọn Quận/Huyện'),
          decoration: InputDecoration(
            labelText: 'Quận/Huyện',
            border: const OutlineInputBorder(),
            suffixIcon: _isLoadingDistricts
                ? const Padding(
              padding: EdgeInsets.all(10.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : null,
          ),
          disabledHint: const Text('Vui lòng chọn Tỉnh/Thành phố trước'),
          items: _districts.map((District district) {
            return DropdownMenuItem<District>(
              value: district,
              child: Text(district.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: _selectedProvince == null
              ? null
              : (District? newValue) {
            setState(() {
              _selectedDistrict = newValue;
            });
            widget.onAddressChanged(
              _selectedProvince?.name,
              newValue?.name,
            );
            widget.onChangedWithCode?.call(
              province: _selectedProvince?.name,
              provinceCode: _selectedProvince?.code,
              district: newValue?.name,
              districtCode: newValue?.code,
            );
          },
          validator: (value) => value == null ? 'Vui lòng chọn Quận/Huyện' : null,
        ),
      ],
    );
  }
}