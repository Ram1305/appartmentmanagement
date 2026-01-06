import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/user_bloc.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/home_tab.dart';
import 'widgets/events_tab.dart';
import 'widgets/complaints_tab.dart';
import 'widgets/profile_tab.dart';

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
}

