import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../bloc/user_bloc.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/home_tab.dart';
import 'widgets/events_tab.dart';
import 'widgets/complaints_tab.dart';
import 'widgets/profile_tab.dart';
import 'visitors_page.dart';
import 'vehicles_page.dart';
import 'terms_and_conditions_page.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(LoadUserDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          return Scaffold(
            drawer: _buildDrawer(context, authState.user),
            appBar: AppBar(
              title: Text(_getAppBarTitle(_currentIndex)),
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: [
                HomeTab(
                  user: authState.user,
                  onSwitchToComplaints: () {
                    setState(() => _currentIndex = 2);
                  },
                ),
                const EventsTab(),
                ComplaintsTab(userId: authState.user.id),
                ProfileTab(user: authState.user),
              ],
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      width: 240,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Compact Header with profile
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image with border
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            backgroundImage: user.profilePic != null
                                ? NetworkImage(user.profilePic!)
                                : null,
                            child: user.profilePic == null
                                ? Icon(
                                    Icons.person,
                                    size: 35,
                                    color: AppTheme.primaryColor,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Center(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Mobile Number
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phone,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                user.mobileNumber,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (user.block != null && user.roomNumber != null) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Block ${user.block} • Room ${user.roomNumber}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Main Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    title: 'Home',
                    index: 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = 0;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.event_rounded,
                    title: 'Events',
                    index: 1,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.report_problem_rounded,
                    title: 'Complaints',
                    index: 2,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = 2;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    index: 3,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = 3;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Secondary Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.people_rounded,
                    title: 'Visitors',
                    isSecondary: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitorsPage(user: user),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.directions_car_rounded,
                    title: 'My Vehicles',
                    isSecondary: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehiclesPage(user: user),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.description_rounded,
                    title: 'Terms & Conditions',
                    isSecondary: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsAndConditionsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Logout Section
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: _buildDrawerItem(
                context,
                icon: Icons.logout_rounded,
                title: 'Logout',
                isLogout: true,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(fontSize: 14),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14),
                          ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? index,
    bool isSecondary = false,
    bool isLogout = false,
  }) {
    final isSelected = index != null && _currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isLogout
                        ? AppTheme.errorColor.withOpacity(0.15)
                        : isSelected
                            ? AppTheme.primaryColor.withOpacity(0.15)
                            : (isSecondary
                                ? AppTheme.textColor.withOpacity(0.08)
                                : AppTheme.primaryColor.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isLogout
                        ? AppTheme.errorColor
                        : isSelected
                            ? AppTheme.primaryColor
                            : (isSecondary
                                ? AppTheme.textColor.withOpacity(0.7)
                                : AppTheme.primaryColor.withOpacity(0.8)),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isLogout
                          ? AppTheme.errorColor
                          : isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textColor,
                      fontSize: 13,
                      fontWeight: isSelected || isLogout
                          ? FontWeight.w600
                          : FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Events';
      case 2:
        return 'Complaints';
      case 3:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }
}

