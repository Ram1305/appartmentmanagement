import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/user_registration_page.dart';
import '../../features/auth/presentation/pages/security_registration_page.dart';
import '../../features/auth/presentation/pages/user_type_selection_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/waiting_approval_page.dart';
import '../guards/admin_route_guard.dart';
import '../../features/admin/presentation/pages/block_details_page.dart';
import '../../features/manager/presentation/pages/manager_dashboard_page.dart';
import '../../features/user/presentation/pages/user_dashboard_page.dart';
import '../../features/security/presentation/pages/security_dashboard_page.dart';
import '../../features/user/presentation/pages/coming_soon_page.dart';
import '../../features/user/presentation/pages/amenities_page.dart';
import '../../features/user/presentation/pages/payments_page.dart';
import '../../features/user/presentation/pages/support_page.dart';
import '../../features/user/presentation/pages/support_chat_page.dart';
import '../../core/models/block_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String userTypeSelection = '/user-type-selection';
  static const String login = '/login';
  static const String userRegistration = '/user-registration';
  static const String securityRegistration = '/security-registration';
  static const String forgotPassword = '/forgot-password';
  static const String waitingApproval = '/waiting-approval';
  static const String adminDashboard = '/admin-dashboard';
  static const String blockDetails = '/block-details';
  static const String managerDashboard = '/manager-dashboard';
  static const String userDashboard = '/user-dashboard';
  static const String securityDashboard = '/security-dashboard';
  static const String featureComingSoon = '/feature-coming-soon';
  static const String amenities = '/amenities';
  static const String payments = '/payments';
  static const String support = '/support';
  static const String supportChat = '/support-chat';

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
      waitingApproval: (context) => const WaitingApprovalPage(),
      adminDashboard: (context) => const AdminRouteGuard(),
      blockDetails: (context) {
        final block = ModalRoute.of(context)!.settings.arguments as BlockModel;
        return BlockDetailsPage(block: block);
      },
      managerDashboard: (context) => const ManagerDashboardPage(),
      userDashboard: (context) => const UserDashboardPage(),
      securityDashboard: (context) => const SecurityDashboardPage(),
      featureComingSoon: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final featureName = args is Map ? args['featureName'] as String? : null;
        return ComingSoonPage(featureName: featureName);
      },
      amenities: (context) => const AmenitiesPage(),
      payments: (context) => const PaymentsPage(),
      support: (context) => const SupportPage(),
      supportChat: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final ticketId = args?['ticketId'] as String? ?? '';
        final isAdmin = args?['isAdmin'] as bool? ?? false;
        return SupportChatPage(ticketId: ticketId, isAdmin: isAdmin);
      },
    };
  }
}

