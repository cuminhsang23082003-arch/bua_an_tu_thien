// lib/features/restaurants/viewmodels/edit_restaurant_viewmodel.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../models/restaurant_model.dart';
import '../repositories/restaurant_repository.dart';

class EditRestaurantViewModel extends ChangeNotifier {
  final RestaurantRepository _restaurantRepository;

  EditRestaurantViewModel({required RestaurantRepository restaurantRepository})
    : _restaurantRepository = restaurantRepository;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<bool> updateRestaurant({
    required RestaurantModel originalRestaurant,
    required String name,
    required String province,
    required String district,
    required String address,
    required String phoneNumber,
    required String description,
    required Map<String, String> operatingHours,
    File? newImageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? imageUrl = originalRestaurant.imageUrl;
      // Nếu có ảnh mới → upload
      if (newImageFile != null) {
        imageUrl = await _restaurantRepository.uploadImage(
          newImageFile,
          originalRestaurant.ownerId,
        );
      }

      // Kiểm tra địa chỉ có thay đổi không
      final bool addressChanged =
          originalRestaurant.province.trim() != province.trim() ||
          originalRestaurant.district.trim() != district.trim() ||
          originalRestaurant.address.trim() != address.trim();

      GeoPoint? newLocation;
      if (addressChanged) {
        final fullAddress = '$address, $district, $province, Việt Nam';
        try {
          final results = await geocoding
              .locationFromAddress(fullAddress)
              .timeout(const Duration(seconds: 8));
          if (results.isNotEmpty) {
            newLocation = GeoPoint(
              results.first.latitude,
              results.first.longitude,
            );
          } else {
            debugPrint('Geocoding trả về rỗng cho: $fullAddress');
          }
        } catch (e) {
          // Không chặn cập nhật nếu geocoding lỗi; giữ nguyên vị trí cũ
          debugPrint('Geocoding thất bại, giữ vị trí cũ: $e');
        }
      }

      final updatedRestaurant = originalRestaurant.copyWith(
        name: name,
        province: province,
        district: district,
        address: address,
        phoneNumber: phoneNumber,
        description: description,
        operatingHours: operatingHours,
        imageUrl: imageUrl,
        // QUAN TRỌNG: set location mới nếu có, ngược lại giữ cũ
        location: newLocation ?? originalRestaurant.location,
      );

      await _restaurantRepository.updateRestaurantAndOwner(
        updatedRestaurant: updatedRestaurant,
        ownerUid: originalRestaurant.ownerId,
        newPhoneNumber: phoneNumber,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Lỗi khi cập nhật: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
