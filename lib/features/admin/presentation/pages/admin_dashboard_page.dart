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
import 'tabs/maintenance_tab.dart';
import 'tabs/tenants_tab.dart';
import 'tabs/payments_tab.dart';
import 'tabs/permissions_tab.dart';
import 'tabs/notices_tab.dart';
import 'tabs/ads_tab.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 11, vsync: this);
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
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Maintenance'),
            Tab(icon: Icon(Icons.how_to_reg), text: 'Tenants'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
            Tab(icon: Icon(Icons.security), text: 'Permissions'),
            Tab(icon: Icon(Icons.notifications), text: 'Notices'),
            Tab(icon: Icon(Icons.campaign), text: 'Ads'),
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
          if (state is AdminError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is AdminLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(state: state),
                BlocksTab(state: state),
                ManagersTab(state: state),
                SecurityTab(state: state),
                UsersTab(state: state),
                MaintenanceTab(state: state),
                TenantsTab(state: state),
                PaymentsTab(state: state),
                PermissionsTab(state: state),
                NoticesTab(state: state),
                AdsTab(state: state),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

