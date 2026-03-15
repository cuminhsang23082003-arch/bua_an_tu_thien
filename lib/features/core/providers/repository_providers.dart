import 'package:buaanyeuthuong/features/authentication/repositories/auth_repository.dart';
import 'package:buaanyeuthuong/features/core/repositories/address_repository.dart';
import 'package:buaanyeuthuong/features/meal_events/repositories/meal_event_repository.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:provider/provider.dart';

import '../../admin/repositories/admin_repository.dart';
import '../../beneficiary/repositories/registration_repository.dart';
import '../../donations/repositories/donation_repository.dart';

final repositoryProviders = [
  Provider<AuthRepository>(create: (_) => AuthRepository()),
  Provider<AdminRepository>(create: (_) => AdminRepository()),
  Provider<AddressRepository>(create: (_) => AddressRepository()),
  Provider<RestaurantRepository>(create: (_) => RestaurantRepository()),
  Provider<MealEventRepository>(create: (_) => MealEventRepository()),
  Provider<RegistrationRepository>(create: (_) => RegistrationRepository()),
  Provider<DonationRepository>(create: (_) => DonationRepository()),
];