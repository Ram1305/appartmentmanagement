import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/models/user_model.dart';

class UserTypeSelectionPage extends StatelessWidget {
  const UserTypeSelectionPage({super.key});

  void _navigateToLogin(BuildContext context, UserType userType) {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: userType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // App Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.apartment,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Apartment Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'System',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Select Login Type',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // User Type Options List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _UserTypeOption(
                          icon: Icons.admin_panel_settings,
                          title: 'Admin',
                          subtitle: 'Administrator Access',
                          color: Colors.red.shade400,
                          onTap: () => _navigateToLogin(context, UserType.admin),
                        ),
                        const SizedBox(height: 16),
                        _UserTypeOption(
                          icon: Icons.business_center,
                          title: 'Manager',
                          subtitle: 'Manager Access',
                          color: Colors.orange.shade400,
                          onTap: () => _navigateToLogin(context, UserType.manager),
                        ),
                        const SizedBox(height: 16),
                        _UserTypeOption(
                          icon: Icons.person,
                          title: 'User',
                          subtitle: 'Resident Access',
                          color: Colors.blue.shade400,
                          onTap: () => _navigateToLogin(context, UserType.user),
                        ),
                        const SizedBox(height: 16),
                        _UserTypeOption(
                          icon: Icons.security,
                          title: 'Security',
                          subtitle: 'Security Personnel Access',
                          color: Colors.green.shade400,
                          onTap: () => _navigateToLogin(context, UserType.security),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _UserTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textColor.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

