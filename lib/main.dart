// lib/main.dart

import 'package:buaanyeuthuong/features/core/providers/repository_providers.dart';
import 'package:buaanyeuthuong/features/core/providers/viewmodel_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/admin/views/admin_main_screen.dart';
import 'features/authentication/models/user_model.dart';
import 'firebase_options.dart';
import 'features/core/services/snackbar_service.dart';
import 'features/authentication/viewmodels/auth_viewmodel.dart';
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
       ...repositoryProviders,
        ...viewModelProviders,
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          return MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
            title: 'Bữa ăn yêu thương',
            debugShowCheckedModeBanner: false, // Tắt chữ Debug góc phải

            theme: ThemeData(
              primarySwatch: Colors.orange,
              useMaterial3: true, inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),

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