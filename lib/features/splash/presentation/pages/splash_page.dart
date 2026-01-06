import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/routes/app_routes.dart';

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
    _startNavigationTimer();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _startNavigationTimer() {
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!_hasNavigated) {
        _navigateToUserTypeSelection();
      }
    });
  }

  void _navigateToUserTypeSelection() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.userTypeSelection,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}

