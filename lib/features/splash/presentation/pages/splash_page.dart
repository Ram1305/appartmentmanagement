import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_update/in_app_update.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _checkForUpdate();
    }
    // React to initial auth state (in case CheckAuthStatus already completed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasNavigated) return;
      final state = context.read<AuthBloc>().state;
      if (state is AuthAuthenticated) {
        _navigationTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_hasNavigated && mounted) _navigateToDashboard(state.user);
        });
      } else if (state is AuthUnauthenticated) {
        _navigationTimer?.cancel();
        _navigationTimer = Timer(const Duration(seconds: 3), () {
          if (!_hasNavigated && mounted) _navigateToUserTypeSelection();
        });
      } else {
        _navigationTimer?.cancel();
        _navigationTimer = Timer(const Duration(seconds: 4), () {
          if (!_hasNavigated && mounted) _navigateToUserTypeSelection();
        });
      }
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          mounted) {
        await InAppUpdate.performImmediateUpdate();
        // If user completes or cancels, we continue with normal flow
      }
    } catch (_) {
      // Ignore: not from Play Store or update not available
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _navigateToUserTypeSelection() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.userTypeSelection);
  }

  void _navigateToDashboard(UserModel user) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    if (!mounted) return;

    String route = AppRoutes.login;
    switch (user.userType) {
      case UserType.admin:
        route = AppRoutes.adminDashboard;
        break;
      case UserType.manager:
        route = AppRoutes.managerDashboard;
        break;
      case UserType.user:
        route = AppRoutes.userDashboard;
        break;
      case UserType.security:
        route = AppRoutes.securityDashboard;
        break;
      default:
        route = AppRoutes.userTypeSelection;
    }

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_hasNavigated) return;
        if (state is AuthAuthenticated) {
          _navigationTimer?.cancel();
          // Short delay so splash is visible, then go to dashboard
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_hasNavigated && mounted) {
              _navigateToDashboard(state.user);
            }
          });
        } else if (state is AuthUnauthenticated) {
          _navigationTimer?.cancel();
          _navigationTimer = Timer(const Duration(seconds: 3), () {
            if (!_hasNavigated && mounted) {
              _navigateToUserTypeSelection();
            }
          });
        } else if (state is AuthLoading || state is AuthInitial) {
          // Cap wait: if still loading after 4s, go to user type selection
          _navigationTimer?.cancel();
          _navigationTimer = Timer(const Duration(seconds: 4), () {
            if (!_hasNavigated && mounted) {
              _navigateToUserTypeSelection();
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: Center(
          child: Image.asset(
            'assets/splashicon.png',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.white,
                child: const Icon(
                  Icons.apartment,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
