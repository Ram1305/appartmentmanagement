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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    // color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/appicon.png',
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
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
                // const SizedBox(height: 10),
                // const Text(
                //   'System',
                //   style: TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.w500,
                //     color: Colors.white70,
                //     letterSpacing: 1.0,
                //   ),
                // ),
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
                // User Type Options Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                    children: [
                      _UserTypeOption(
                        icon: Icons.admin_panel_settings,
                        title: 'Admin',
                        subtitle: 'Administrator Access',
                        color: Colors.red.shade400,
                        onTap: () => _navigateToLogin(context, UserType.admin),
                      ),
                      // _UserTypeOption(
                      //   icon: Icons.business_center,
                      //   title: 'Manager',
                      //   subtitle: 'Manager Access',
                      //   color: Colors.orange.shade400,
                      //   onTap: () => _navigateToLogin(context, UserType.manager),
                      // ),
                      _UserTypeOption(
                        icon: Icons.person,
                        title: 'User',
                        subtitle: 'Resident Access',
                        color: Colors.blue.shade400,
                        onTap: () => _navigateToLogin(context, UserType.user),
                      ),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              // const SizedBox(height: 4),
             
            ],
          ),
        ),
      ),
    );
  }
}

