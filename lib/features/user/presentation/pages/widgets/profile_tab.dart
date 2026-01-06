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
            // Compact Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.85),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  // Compact Profile Picture
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: user.profilePic != null
                          ? ClipOval(
                              child: Image.network(
                                user.profilePic!,
                                fit: BoxFit.cover,
                                width: 70,
                                height: 70,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 35,
                              color: AppTheme.primaryColor,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.status == AccountStatus.approved
                                ? Colors.green.withOpacity(0.9)
                                : user.status == AccountStatus.pending
                                    ? Colors.orange.withOpacity(0.9)
                                    : Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.status.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Compact Info Cards Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Section
                  _buildSectionHeader('Personal Information', Icons.person_outline),
                  const SizedBox(height: 10),
                  // Compact grid layout for personal info
                  _buildCompactInfoCard(
                    'Username',
                    user.username,
                    Icons.person_outline_rounded,
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactInfoCard(
                    'Email',
                    user.email,
                    Icons.email_outlined,
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactInfoCard(
                          'Mobile',
                          user.mobileNumber,
                          Icons.phone_outlined,
                          AppTheme.secondaryColor,
                        ),
                      ),
                      if (user.secondaryMobileNumber != null && user.secondaryMobileNumber!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactInfoCard(
                            'Secondary',
                            user.secondaryMobileNumber!,
                            Icons.phone_android_outlined,
                            AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (user.gender != null) ...[
                    const SizedBox(height: 8),
                    _buildCompactInfoCard(
                      'Gender',
                      user.gender!.name.toUpperCase(),
                      Icons.wc_outlined,
                      AppTheme.accentColor,
                    ),
                  ],
                  if (user.address != null && user.address!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCompactInfoCard(
                      'Address',
                      user.address!,
                      Icons.home_outlined,
                      AppTheme.accentColor,
                    ),
                  ],
                  
                  // Tenant Details Section
                  if (user.familyType != null || user.totalOccupants != null || 
                      user.block != null || user.floor != null || user.roomNumber != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader('Tenant Details', Icons.home_work_outlined),
                    const SizedBox(height: 10),
                  ],
                  if (user.familyType != null || user.totalOccupants != null) ...[
                    Row(
                      children: [
                        if (user.familyType != null)
                          Expanded(
                            child: _buildCompactInfoCard(
                              'Family Type',
                              user.familyType!.name.toUpperCase(),
                              Icons.family_restroom,
                              AppTheme.primaryColor,
                            ),
                          ),
                        if (user.familyType != null && user.totalOccupants != null)
                          const SizedBox(width: 8),
                        if (user.totalOccupants != null)
                          Expanded(
                            child: _buildCompactInfoCard(
                              'Occupants',
                              user.totalOccupants.toString(),
                              Icons.people_outline,
                              AppTheme.secondaryColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (user.block != null || user.floor != null || user.roomNumber != null) ...[
                    Row(
                      children: [
                        if (user.block != null && user.block!.isNotEmpty)
                          Expanded(
                            child: _buildCompactInfoCard(
                              'Block',
                              user.block!,
                              Icons.apartment_outlined,
                              AppTheme.secondaryColor,
                            ),
                          ),
                        if (user.block != null && user.floor != null && user.floor!.isNotEmpty)
                          const SizedBox(width: 8),
                        if (user.floor != null && user.floor!.isNotEmpty)
                          Expanded(
                            child: _buildCompactInfoCard(
                              'Floor',
                              user.floor!,
                              Icons.stairs_outlined,
                              AppTheme.accentColor,
                            ),
                          ),
                        if ((user.block != null || user.floor != null) && user.roomNumber != null && user.roomNumber!.isNotEmpty)
                          const SizedBox(width: 8),
                        if (user.roomNumber != null && user.roomNumber!.isNotEmpty)
                          Expanded(
                            child: _buildCompactInfoCard(
                              'Room',
                              user.roomNumber!,
                              Icons.door_front_door_outlined,
                              AppTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                  
                  // Identity Documents Section
                  if (user.aadhaarCard != null || user.panCard != null ||
                      user.aadhaarCardFrontImage != null || user.aadhaarCardBackImage != null ||
                      user.panCardImage != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader('Identity Documents', Icons.badge_outlined),
                    const SizedBox(height: 10),
                  ],
                  if (user.aadhaarCard != null && user.aadhaarCard!.isNotEmpty) ...[
                    _buildCompactInfoCard(
                      'Aadhaar',
                      user.aadhaarCard!,
                      Icons.badge_outlined,
                      AppTheme.secondaryColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (user.aadhaarCardFrontImage != null || user.aadhaarCardBackImage != null) ...[
                    Row(
                      children: [
                        if (user.aadhaarCardFrontImage != null)
                          Expanded(
                            child: _buildCompactImageCard(
                              'Aadhaar Front',
                              user.aadhaarCardFrontImage!,
                            ),
                          ),
                        if (user.aadhaarCardFrontImage != null && user.aadhaarCardBackImage != null)
                          const SizedBox(width: 8),
                        if (user.aadhaarCardBackImage != null)
                          Expanded(
                            child: _buildCompactImageCard(
                              'Aadhaar Back',
                              user.aadhaarCardBackImage!,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (user.panCard != null && user.panCard!.isNotEmpty) ...[
                    _buildCompactInfoCard(
                      'PAN Card',
                      user.panCard!,
                      Icons.credit_card_outlined,
                      AppTheme.accentColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (user.panCardImage != null) ...[
                    _buildCompactImageCard(
                      'PAN Card',
                      user.panCardImage!,
                    ),
                  ],
                  
                  const SizedBox(height: 20),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfoCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textColor.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactImageCard(String label, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor.withOpacity(0.7),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
                      const SizedBox(height: 4),
                      Text(
                        'Failed',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.grey[100],
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

