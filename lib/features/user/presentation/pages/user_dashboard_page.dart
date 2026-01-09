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
            body: IndexedStack(
              index: _currentIndex,
              children: [
                HomeTab(user: authState.user),
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with profile
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Profile Image
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: user.profilePic != null
                        ? NetworkImage(user.profilePic!)
                        : null,
                    child: user.profilePic == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Center(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Mobile Number
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        user.mobileNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Menu Items
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home',
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 3;
              });
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.event,
            title: 'Events',
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.report_problem,
            title: 'Complaints',
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Visitors',
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
            icon: Icons.description,
            title: 'Terms and Conditions',
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
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
              Navigator.pushReplacementNamed(context, AppRoutes.userTypeSelection);
            },
            textColor: AppTheme.errorColor,
            iconColor: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppTheme.textColor,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}

