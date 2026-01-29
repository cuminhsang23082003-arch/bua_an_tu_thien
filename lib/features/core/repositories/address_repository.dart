// lib/core/repositories/address_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Province {
  final String name;
  final int code;
  Province({required this.name, required this.code});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      // hỗ trợ các dạng key: name | Name | province_name | full_name
      name: ((json['name'] ?? json['Name'] ?? json['province_name'] ?? json['full_name']) as String? ?? '').trim(),
      // hỗ trợ: code | Code | Id | id | province_id
      code: _toInt(json['code'] ?? json['Code'] ?? json['Id'] ?? json['id'] ?? json['province_id']),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class District {
  final String name;
  final int code;
  District({required this.name, required this.code});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      // hỗ trợ: name | Name | district_name | full_name
      name: ((json['name'] ?? json['Name'] ?? json['district_name'] ?? json['full_name']) as String? ?? '').trim(),
      // hỗ trợ: code | Code | Id | id | district_id
      code: _toInt(json['code'] ?? json['Code'] ?? json['Id'] ?? json['id'] ?? json['district_id']),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class AddressRepository {
  static const String _assetPath = 'assets/data/vietnam_provinces.json';

  List<Province>? _provincesCache;
  final Map<int, List<District>> _districtsByProvince = {};

  Future<List<Province>> getProvinces({bool forceRefresh = false}) async {
    if (!forceRefresh && _provincesCache != null) return _provincesCache!;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw);

    // Hỗ trợ 2 dạng:
    // - List [... {province object} ...]
    // - Map {"provinces": [ ... ]}
    final List<dynamic> provincesRaw = decoded is List
        ? decoded
        : (decoded is Map && decoded['provinces'] is List)
        ? decoded['provinces'] as List
        : <dynamic>[];

    _districtsByProvince.clear();

    final provinces = provincesRaw.map<Province>((p) {
      final provMap = _normalizeMap(p);
      final province = Province.fromJson(provMap);

      // Lấy danh sách huyện (districts | Districts)
      final districtsRaw = (provMap['districts'] ?? provMap['Districts']) as List<dynamic>? ?? const [];
      final districts = districtsRaw
          .map((d) => District.fromJson(_normalizeMap(d)))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _districtsByProvince[province.code] = districts;
      return province;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    _provincesCache = provinces;
    return provinces;
  }

  Future<List<District>> getDistricts(int provinceCode, {bool forceRefresh = false}) async {
    if (forceRefresh || _provincesCache == null) {
      await getProvinces(forceRefresh: forceRefresh);
    }
    return _districtsByProvince[provinceCode] ?? [];
  }

  void clearCache() {
    _provincesCache = null;
    _districtsByProvince.clear();
  }

  Map<String, dynamic> _normalizeMap(dynamic input) {
    if (input is Map<String, dynamic>) return input;
    if (input is Map) return input.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }
}