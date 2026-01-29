import 'package:buaanyeuthuong/features/meal_events/viewmodels/create_meal_event_viewmodel.dart';
import 'package:buaanyeuthuong/features/meal_events/viewmodels/edit_meal_event_viewmodel.dart';
import 'package:buaanyeuthuong/features/restaurants/viewmodels/edit_restaurant_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/core/services/snackbar_service.dart';
import 'features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'features/dashboard/views/dashboard_router.dart';
import 'features/authentication/repositories/auth_repository.dart';
import 'features/authentication/viewmodels/auth_viewmodel.dart';
import 'features/authentication/views/auth_screen.dart';
import 'features/beneficiary/viewmodels/profile_viewmodel.dart';
import 'features/donations/repositories/donation_repository.dart';
import 'features/donations/viewmodels/donation_viewmodel.dart';
import 'firebase_options.dart';
import 'features/restaurants/repositories/restaurant_repository.dart';
import 'features/meal_events/repositories/meal_event_repository.dart';
import 'features/restaurants/viewmodels/create_restaurant_viewmodel.dart';
import 'features/beneficiary/viewmodels/beneficiary_viewmodel.dart';
import 'features/beneficiary/repositories/registration_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<RestaurantRepository>(create: (_) => RestaurantRepository()),
        Provider<MealEventRepository>(create: (_) => MealEventRepository()),
        Provider<RegistrationRepository>(
          create: (_) => RegistrationRepository(),
        ),
        Provider<DonationRepository>(create: (_) => DonationRepository()),
        Provider<DashboardViewModel>(
          create: (context) => DashboardViewModel(
            authRepository: context.read<AuthRepository>(),
            registrationRepository: context.read<RegistrationRepository>(),
            mealEventRepository: context.read<MealEventRepository>(),
            donationRepository: context.read<DonationRepository>(),
          ),
        ),


        ChangeNotifierProvider<AuthViewModel>(
          create: (context) =>
              AuthViewModel(authRepository: context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<CreateRestaurantViewModel>(
          create: (context) => CreateRestaurantViewModel(
            restaurantRepository: context.read<RestaurantRepository>(),
          ),
        ),
        ChangeNotifierProvider<CreateMealEventViewModel>(
          create: (context) => CreateMealEventViewModel(
            mealEventRepository: context.read<MealEventRepository>(),
          ),
        ),
        ChangeNotifierProvider<EditRestaurantViewModel>(
          create: (context) => EditRestaurantViewModel(
            restaurantRepository: context.read<RestaurantRepository>(),
          ),
        ),

        ChangeNotifierProvider<EditMealEventViewModel>(
          create: (context) => EditMealEventViewModel(
            mealEventRepository: context.read<MealEventRepository>(),
          ),
        ),

        ChangeNotifierProvider<BeneficiaryViewModel>(
          create: (context) => BeneficiaryViewModel(
            registrationRepository: context.read<RegistrationRepository>(),
          ),
        ),
        ChangeNotifierProvider<ProfileViewModel>(
          create: (context) =>
              ProfileViewModel(authRepository: context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<DonationViewModel>(
          create: (context) => DonationViewModel(
            donationRepository: context.read<DonationRepository>(),
          ),
        ),
      ],
      // Consumer ở dưới sẽ tự động lấy đúng AuthViewModel từ context.
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          return MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
            title: 'Bữa ăn yêu thương',
            theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
            home: _buildHome(authViewModel), // Tách ra cho gọn
          );
        },
      ),
    );
  }

  // REASON: Tách logic điều hướng ra một hàm riêng cho dễ đọc.
  Widget _buildHome(AuthViewModel authViewModel) {
    switch (authViewModel.status) {
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B6B)),
          ),
        );
      case AuthStatus.authenticated:
        // Đảm bảo currentUser không null trước khi điều hướng
        if (authViewModel.currentUser != null) {
          return DashboardRouter(user: authViewModel.currentUser!);
        }
        // Nếu currentUser null dù đã authenticated (trường hợp lỗi), quay về AuthScreen
        return const AuthScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      case AuthStatus.initial:
      default:
        return const AuthScreen();
    }
  }
}
