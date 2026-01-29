import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/admin_bloc.dart';
import 'tabs/overview_tab.dart';
import 'tabs/blocks_tab.dart';
import 'tabs/managers_tab.dart';
import 'tabs/security_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/assign_payments_tab.dart';
import 'tabs/payments_tab.dart';
import 'tabs/notices_tab.dart';
import 'tabs/ads_tab.dart';
import 'tabs/amenities_tab.dart';
import 'tabs/support_tab.dart';
import 'tabs/subscription_tab.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AdminLoaded? _lastLoadedState;
  bool _errorSnackBarShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 12, vsync: this);
    context.read<AdminBloc>().add(LoadBlocksEvent());
    // Initialize dummy data on first load
    context.read<AdminBloc>().add(InitializeDummyDataEvent());
    
    // Check if we need to switch to a specific tab (e.g., returning from registration)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['tabIndex'] != null) {
        _tabController.animateTo(args['tabIndex'] as int);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.apartment), text: 'Blocks'),
            Tab(icon: Icon(Icons.people), text: 'Managers'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.person), text: 'Users'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Assign Payments'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
            Tab(icon: Icon(Icons.notifications), text: 'Notices'),
            Tab(icon: Icon(Icons.campaign), text: 'Ads'),
            Tab(icon: Icon(Icons.spa), text: 'Amenities'),
            Tab(icon: Icon(Icons.support_agent), text: 'Support'),
            Tab(icon: Icon(Icons.card_membership), text: 'Subscription'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
              Navigator.pushReplacementNamed(context, AppRoutes.userTypeSelection);
            },
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminLoaded) {
            _lastLoadedState = state;
            _errorSnackBarShown = false;
            return TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(state: state),
                BlocksTab(state: state),
                ManagersTab(state: state),
                SecurityTab(state: state),
                UsersTab(state: state),
                AssignPaymentsTab(state: state),
                PaymentsTab(
                  state: state,
                  parentTabController: _tabController,
                  parentTabIndex: 6,
                ),
                NoticesTab(state: state),
                AdsTab(state: state),
                AmenitiesTab(state: state),
                const SupportTab(),
                const SubscriptionTab(),
              ],
            );
          }
          if (state is AdminError) {
            if (_lastLoadedState != null) {
              if (!_errorSnackBarShown) {
                _errorSnackBarShown = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () {
                          context.read<AdminBloc>().add(LoadBlocksEvent());
                        },
                      ),
                    ),
                  );
                  context.read<AdminBloc>().add(LoadBlocksEvent());
                });
              }
              return TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(state: _lastLoadedState!),
                  BlocksTab(state: _lastLoadedState!),
                  ManagersTab(state: _lastLoadedState!),
                  SecurityTab(state: _lastLoadedState!),
                  UsersTab(state: _lastLoadedState!),
                  AssignPaymentsTab(state: _lastLoadedState!),
                  PaymentsTab(
                    state: _lastLoadedState!,
                    parentTabController: _tabController,
                    parentTabIndex: 6,
                  ),
                  NoticesTab(state: _lastLoadedState!),
                  AdsTab(state: _lastLoadedState!),
                  AmenitiesTab(state: _lastLoadedState!),
                  const SupportTab(),
                  const SubscriptionTab(),
                ],
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<AdminBloc>().add(LoadBlocksEvent()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

