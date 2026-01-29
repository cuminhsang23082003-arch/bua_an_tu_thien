// lib/features/restaurants/viewmodels/create_restaurant_viewmodel.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import '../../authentication/models/user_model.dart';
import '../models/restaurant_model.dart';
import '../repositories/restaurant_repository.dart';

class CreateRestaurantViewModel extends ChangeNotifier {
  final RestaurantRepository _restaurantRepository;

  CreateRestaurantViewModel({
    required RestaurantRepository restaurantRepository,
  }) : _restaurantRepository = restaurantRepository;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<bool> createRestaurant({
    required String name,
    required String province,
    required String district,
    required String address,
    required String phoneNumber,
    required String description,
    required UserModel owner,
    File? imageFile,
    required Map<String, String> operatingHours,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      //Ghep cac thanh phan dia chi lai thanh 1 chuoi day du
      final String fullAddress ='$address, $district, $province,Việt Nam';
      GeoPoint location = const GeoPoint(0, 0);

      try{
        //2.Goi API de chuyen doi dia chi thanh toa do
        List<Location> locations = await locationFromAddress(fullAddress);
        if(locations.isNotEmpty){
          location = GeoPoint(locations.first.latitude, locations.first.longitude);
        }
      }catch(e){
        print("Lỗi Geocoding, sử dụng vị trí mặc định: $e");
      }
      String? imageUrl;
      if (imageFile != null) {
        // Gọi hàm uploadImage "giả"
        imageUrl = await _restaurantRepository.uploadImage(
          imageFile,
          owner.uid,
        );
      }
      final newRestaurant = RestaurantModel(
        id: '',
        // Firestore sẽ tự tạo ID
        ownerId: owner.uid,
        name: name,
        province: province,
        district: district,
        address: address,
        phoneNumber: phoneNumber,
        description: description,
        operatingHours: operatingHours,
        location: location,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _restaurantRepository.createRestaurant(newRestaurant);

      _isLoading = false;
      notifyListeners();
      return true; // Thành công
    } catch (e) {
      _errorMessage = "Đã có lỗi xảy ra: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false; // Thất bại
    }
  }
}
