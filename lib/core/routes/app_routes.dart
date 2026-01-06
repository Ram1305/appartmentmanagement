import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/user_registration_page.dart';
import '../../features/auth/presentation/pages/security_registration_page.dart';
import '../../features/auth/presentation/pages/user_type_selection_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/block_details_page.dart';
import '../../features/manager/presentation/pages/manager_dashboard_page.dart';
import '../../features/user/presentation/pages/user_dashboard_page.dart';
import '../../features/security/presentation/pages/security_dashboard_page.dart';
import '../../core/models/block_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String userTypeSelection = '/user-type-selection';
  static const String login = '/login';
  static const String userRegistration = '/user-registration';
  static const String securityRegistration = '/security-registration';
  static const String forgotPassword = '/forgot-password';
  static const String adminDashboard = '/admin-dashboard';
  static const String blockDetails = '/block-details';
  static const String managerDashboard = '/manager-dashboard';
  static const String userDashboard = '/user-dashboard';
  static const String securityDashboard = '/security-dashboard';

  static Map<String, WidgetBuilder> get routes {
    return {
      userTypeSelection: (context) => const UserTypeSelectionPage(),
      login: (context) => const LoginPage(),
      userRegistration: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final fromAdmin = args is Map && args['fromAdmin'] == true;
        return UserRegistrationPage(fromAdmin: fromAdmin);
      },
      securityRegistration: (context) => const SecurityRegistrationPage(),
      forgotPassword: (context) => const ForgotPasswordPage(),
      adminDashboard: (context) => const AdminDashboardPage(),
      blockDetails: (context) {
        final block = ModalRoute.of(context)!.settings.arguments as BlockModel;
        return BlockDetailsPage(block: block);
      },
      managerDashboard: (context) => const ManagerDashboardPage(),
      userDashboard: (context) => const UserDashboardPage(),
      securityDashboard: (context) => const SecurityDashboardPage(),
    };
  }
}

