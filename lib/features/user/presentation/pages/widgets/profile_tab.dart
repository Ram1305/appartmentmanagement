import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/app_theme.dart';
import '../../../../../../core/models/user_model.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';

class ProfileTab extends StatelessWidget {
  final UserModel user;

  const ProfileTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with Gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
              child: Column(
                children: [
                  // Profile Picture with Shadow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: user.profilePic != null
                          ? ClipOval(
                              child: Image.network(
                                user.profilePic!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.primaryColor,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: user.status == AccountStatus.approved
                          ? AppTheme.secondaryColor
                          : AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      user.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Cards Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCard(
                    'Email',
                    user.email,
                    Icons.email_outlined,
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Mobile',
                    user.mobileNumber,
                    Icons.phone_outlined,
                    AppTheme.secondaryColor,
                  ),
                  if (user.address != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Address',
                      user.address!,
                      Icons.home_outlined,
                      AppTheme.accentColor,
                    ),
                  ],
                  if (user.familyType != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Family Type',
                      user.familyType!.name.toUpperCase(),
                      Icons.family_restroom,
                      AppTheme.primaryColor,
                    ),
                  ],
                  if (user.block != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Block',
                      user.block!,
                      Icons.apartment_outlined,
                      AppTheme.secondaryColor,
                    ),
                  ],
                  if (user.floor != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Floor',
                      user.floor!,
                      Icons.stairs_outlined,
                      AppTheme.accentColor,
                    ),
                  ],
                  if (user.roomNumber != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Room',
                      user.roomNumber!,
                      Icons.door_front_door_outlined,
                      AppTheme.primaryColor,
                    ),
                  ],
                  if (user.aadhaarCard != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Aadhaar',
                      user.aadhaarCard!,
                      Icons.badge_outlined,
                      AppTheme.secondaryColor,
                    ),
                  ],
                  if (user.panCard != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'PAN',
                      user.panCard!,
                      Icons.credit_card_outlined,
                      AppTheme.accentColor,
                    ),
                  ],
                  const SizedBox(height: 30),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<AuthBloc>().add(LogoutEvent());
                                  Navigator.pop(context);
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.userTypeSelection,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.errorColor,
                                ),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textColor.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

