import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';

/// Ensures only admins can access the Admin Dashboard.
/// Non-admins and unauthenticated users are redirected to user-type selection.
class AdminRouteGuard extends StatefulWidget {
  const AdminRouteGuard({super.key});

  @override
  State<AdminRouteGuard> createState() => _AdminRouteGuardState();
}

class _AdminRouteGuardState extends State<AdminRouteGuard> {
  bool _redirecting = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_redirecting) return;
        if (state is AuthAuthenticated) {
          if (state.user.userType != UserType.admin) {
            _redirecting = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.userTypeSelection);
              }
            });
          }
        } else if (state is AuthUnauthenticated || state is AuthError) {
          _redirecting = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.userTypeSelection);
            }
          });
        }
      },
      builder: (context, state) {
        if (state is AuthAuthenticated && state.user.userType == UserType.admin) {
          return const AdminDashboardPage();
        }
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
