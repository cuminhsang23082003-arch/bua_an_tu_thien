import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:buaanyeuthuong/features/beneficiary/repositories/registration_repository.dart';
import 'package:buaanyeuthuong/features/beneficiary/viewmodels/beneficiary_viewmodel.dart';
import 'package:buaanyeuthuong/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:buaanyeuthuong/features/donations/repositories/donation_repository.dart';
import 'package:buaanyeuthuong/features/donations/viewmodels/donation_viewmodel.dart';
import 'package:buaanyeuthuong/features/meal_events/repositories/meal_event_repository.dart';
import 'package:buaanyeuthuong/features/restaurants/repositories/restaurant_repository.dart';
import 'package:buaanyeuthuong/features/restaurants/viewmodels/create_restaurant_viewmodel.dart';
import 'package:buaanyeuthuong/features/restaurants/viewmodels/edit_restaurant_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../authentication/repositories/auth_repository.dart';
import '../../meal_events/viewmodels/create_meal_event_viewmodel.dart';
import '../../meal_events/viewmodels/edit_meal_event_viewmodel.dart';

final viewModelProviders =[
  ChangeNotifierProvider<AuthViewModel>(
    create: (context) => AuthViewModel
      (authRepository: context.read<AuthRepository>(),
    ),
  ),

  Provider<DashboardViewModel>(
      create: (context) => DashboardViewModel(
          authRepository: context.read<AuthRepository>(),
          registrationRepository: context.read<RegistrationRepository>(),
          mealEventRepository: context.read<MealEventRepository>(),
          donationRepository: context.read<DonationRepository>(),
      ),
  ),

  ChangeNotifierProvider<CreateRestaurantViewModel>(
    create: (context) => CreateRestaurantViewModel(
      restaurantRepository: context.read<RestaurantRepository>(),
    ),
  ),

  ChangeNotifierProvider<EditRestaurantViewModel>(
      create: (context) => EditRestaurantViewModel(
          restaurantRepository: context.read<RestaurantRepository>(),
      ),
  ),

  ChangeNotifierProvider<BeneficiaryViewModel>(
      create: (context) =>BeneficiaryViewModel(
          registrationRepository: context.read<RegistrationRepository>(),
          mealEventRepository: context.read<MealEventRepository>(),
      ),
  ),

  ChangeNotifierProvider<DonationViewModel>(
      create: (context)=> DonationViewModel(
          donationRepository: context.read<DonationRepository>(),
      ),
  ),

  ChangeNotifierProvider<CreateMealEventViewModel>(
    create: (context) => CreateMealEventViewModel(
      mealEventRepository: context.read<MealEventRepository>(),
    ),
  ),

  ChangeNotifierProvider<EditMealEventViewModel>(
    create: (context) => EditMealEventViewModel(
      mealEventRepository: context.read<MealEventRepository>(),
    ),
  ),
];