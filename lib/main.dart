import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:trashpicker/firebase_options.dart';
import 'services/auth_service.dart';
import 'services/cloudinary_service.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/auth_choice_screen.dart';
import 'features/auth/signup_phone_screen.dart';
import 'features/auth/signup_otp_screen.dart';
import 'features/auth/complete_profile_screen_new.dart';
import 'features/auth/login_screen.dart';
import 'features/client/client_home_screen.dart';
import 'features/client/account_screen.dart';
import 'features/picker/picker_home_screen.dart';
import 'features/picker/picker_account_screen.dart';
import 'features/picker/picker_history_screen.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/admin/admin_client_details_screen.dart';
import 'features/admin/admin_client_history_screen.dart';
import 'features/admin/admin_picker_details_screen.dart';
import 'features/admin/admin_picker_history_screen.dart';
import 'bindings/client_binding.dart';
import 'bindings/picker_binding.dart';
import 'bindings/admin_binding.dart';
import 'core/auth_wrapper.dart';
import 'core/role_middleware.dart';
import 'models/app_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Get.put(AuthService());
  Get.put(CloudinaryService());
  runApp(const TrashPickerApp());
}

class TrashPickerApp extends StatelessWidget {
  const TrashPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TrashPicker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      getPages: [
        // Auth Wrapper - Point d'entrée principal
        GetPage(name: '/', page: () => const AuthWrapper()),

        // Welcome & Auth
        GetPage(name: '/welcome', page: () => const WelcomeScreen()),
        GetPage(name: '/auth-choice', page: () => const AuthChoiceScreen()),
        GetPage(name: '/signup', page: () => const SignupPhoneScreen()),
        GetPage(name: '/signup-otp', page: () => const SignupOtpScreen()),
        GetPage(name: '/complete-profile', page: () => const CompleteProfileScreenNew()),
        GetPage(name: '/login', page: () => const LoginScreen()),

        // Client - Protégé par RoleGuard
        GetPage(
          name: '/client-home',
          page: () => const RoleGuard(
            allowedRoles: [UserRole.client],
            child: ClientHomeScreen(),
          ),
          binding: ClientBinding(),
        ),
        GetPage(name: '/account', page: () => const AccountScreen()),

        // Picker - Protégé par RoleGuard
        GetPage(
          name: '/picker-home',
          page: () => const RoleGuard(
            allowedRoles: [UserRole.picker],
            child: PickerHomeScreen(),
          ),
          binding: PickerBinding(),
        ),
        GetPage(
          name: '/picker-account',
          page: () => const RoleGuard(
            allowedRoles: [UserRole.picker],
            child: PickerAccountScreen(),
          ),
        ),
        GetPage(
          name: '/picker-history',
          page: () => const RoleGuard(
            allowedRoles: [UserRole.picker],
            child: PickerHistoryScreen(),
          ),
        ),

        // Admin - Protégé par RoleGuard
        GetPage(
          name: '/admin-home',
          page: () => const RoleGuard(
            allowedRoles: [UserRole.admin],
            child: AdminHomeScreen(),
          ),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin-client-details',
          page: () => const RoleGuard(
            allowedRoles: [UserRole.admin],
            child: AdminClientDetailsScreen(),
          ),
        ),
        GetPage(
          name: '/admin-client-history',
          page: () => const RoleGuard(
            allowedRoles: [UserRole.admin],
            child: AdminClientHistoryScreen(),
          ),
        ),
        GetPage(
          name: '/admin-picker-details',
          page: () => const RoleGuard(
            allowedRoles: [UserRole.admin],
            child: AdminPickerDetailsScreen(),
          ),
        ),
        GetPage(
          name: '/admin-picker-history',
          page: () => const RoleGuard(
            allowedRoles: [UserRole.admin],
            child: AdminPickerHistoryScreen(),
          ),
        ),
      ],
    );
  }
}
