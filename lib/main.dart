import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // [MỚI] Để hỗ trợ tiếng Việt

// --- Services & Config ---
import 'features/admin/repositories/admin_repository.dart';
import 'features/admin/views/admin_main_screen.dart';
import 'features/authentication/models/user_model.dart';
import 'firebase_options.dart';
import 'features/core/services/snackbar_service.dart';

// --- Repositories ---
import 'features/core/repositories/address_repository.dart'; // [MỚI] Quan trọng: Import AddressRepository
import 'features/authentication/repositories/auth_repository.dart';
import 'features/restaurants/repositories/restaurant_repository.dart';
import 'features/meal_events/repositories/meal_event_repository.dart';
import 'features/beneficiary/repositories/registration_repository.dart';
import 'features/donations/repositories/donation_repository.dart';

// --- ViewModels ---
import 'features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'features/authentication/viewmodels/auth_viewmodel.dart';
import 'features/restaurants/viewmodels/create_restaurant_viewmodel.dart';
import 'features/restaurants/viewmodels/edit_restaurant_viewmodel.dart';
import 'features/meal_events/viewmodels/create_meal_event_viewmodel.dart';
import 'features/meal_events/viewmodels/edit_meal_event_viewmodel.dart';
import 'features/beneficiary/viewmodels/beneficiary_viewmodel.dart';
import 'features/beneficiary/viewmodels/profile_viewmodel.dart';
import 'features/donations/viewmodels/donation_viewmodel.dart';

// --- Views ---
import 'features/dashboard/views/dashboard_router.dart';
import 'features/authentication/views/auth_screen.dart';

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
        // --- 1. LEVEL THẤP: REPOSITORIES ---
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<AdminRepository>(create: (_) => AdminRepository()),

        // [QUAN TRỌNG] Phải cung cấp AddressRepository để tính năng chọn Tỉnh/Huyện hoạt động
        Provider<AddressRepository>(create: (_) => AddressRepository()),

        Provider<RestaurantRepository>(create: (_) => RestaurantRepository()),
        Provider<MealEventRepository>(create: (_) => MealEventRepository()),
        Provider<RegistrationRepository>(create: (_) => RegistrationRepository()),
        Provider<DonationRepository>(create: (_) => DonationRepository()),

        // --- 2. LEVEL CAO: VIEWMODELS ---
        Provider<DashboardViewModel>(
          create: (context) => DashboardViewModel(
            authRepository: context.read<AuthRepository>(),
            registrationRepository: context.read<RegistrationRepository>(),
            mealEventRepository: context.read<MealEventRepository>(),
            donationRepository: context.read<DonationRepository>(),
          ),
        ),

        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(authRepository: context.read<AuthRepository>()),
        ),

        // Các ViewModel cần AddressRepository và RestaurantRepository
        ChangeNotifierProvider<CreateRestaurantViewModel>(
          create: (context) => CreateRestaurantViewModel(
            restaurantRepository: context.read<RestaurantRepository>(),
            // Lưu ý: Nếu ViewModel này cần AddressRepo, hãy thêm: addressRepository: context.read<AddressRepository>(),
          ),
        ),
        ChangeNotifierProvider<EditRestaurantViewModel>(
          create: (context) => EditRestaurantViewModel(
            restaurantRepository: context.read<RestaurantRepository>(),
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

        ChangeNotifierProvider<BeneficiaryViewModel>(
          create: (context) => BeneficiaryViewModel(
            registrationRepository: context.read<RegistrationRepository>(),
            // [BỔ SUNG] Thường ViewModel này cần MealEventRepo để hiển thị thông tin bữa ăn trên vé
            mealEventRepository: context.read<MealEventRepository>(),
          ),
        ),
        ChangeNotifierProvider<ProfileViewModel>(
          create: (context) => ProfileViewModel(authRepository: context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<DonationViewModel>(
          create: (context) => DonationViewModel(
            donationRepository: context.read<DonationRepository>(),
          ),
        ),
      ],

      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          return MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
            title: 'Bữa ăn yêu thương',
            debugShowCheckedModeBanner: false, // Tắt chữ Debug góc phải

            theme: ThemeData(
              primarySwatch: Colors.orange,
              useMaterial3: true,
              // Làm đẹp ô nhập liệu mặc định
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),

            // [MỚI] Cấu hình Tiếng Việt cho Lịch & Đồng hồ
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('vi', 'VN'), // Ưu tiên Tiếng Việt
              Locale('en', 'US'),
            ],

            home: _buildHome(authViewModel),
          );
        },
      ),
    );
  }

  Widget _buildHome(AuthViewModel authViewModel) {
    switch (authViewModel.status) {
      case AuthStatus.loading:
      case AuthStatus.initial: // Thêm case initial để tránh màn hình trắng
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        );
      case AuthStatus.authenticated:
        if (authViewModel.currentUser != null) {
          if (authViewModel.currentUser!.role == UserRole.admin) {
            return const AdminScreen();
          }
          if (authViewModel.currentUser!.isActive == false) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text("Tài khoản của bạn đã bị khóa.", style: TextStyle(fontSize: 18)),
                    TextButton(
                        onPressed: () => authViewModel.signOut(),
                        child: const Text("Đăng xuất")
                    )
                  ],
                ),
              ),
            );
          }
          return DashboardRouter(user: authViewModel.currentUser!);
        }

        return const AuthScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      default:
        return const AuthScreen();
    }
  }
}