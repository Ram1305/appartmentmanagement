import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/manager_bloc.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<ManagerBloc>().add(LoadManagerDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _OverviewTab(
            onNavigateToTab: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          const _TenantsTab(),
          const _ComplaintsTab(),
          const _SecurityTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Tenants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Security',
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Function(int)? onNavigateToTab;
  
  const _OverviewTab({this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManagerBloc, ManagerState>(
      builder: (context, state) {
        if (state is ManagerLoaded) {
          final totalTenants = state.users.where((u) => u.userType == UserType.user).length;
          final approvedUsers = state.users.where((u) => u.userType == UserType.user && u.status == AccountStatus.approved).length;
          final pendingComplaints = state.complaints.where((c) => c.status == ComplaintStatus.pending).length;
          final securityStaff = state.users.where((u) => u.userType == UserType.security).length;
          final totalComplaints = state.complaints.length;
          final resolvedComplaints = state.complaints.where((c) => c.status == ComplaintStatus.resolved).length;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your apartment complex efficiently',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                // Grid View - 2x2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildGridCard(
                      context,
                      'Tenants',
                      totalTenants.toString(),
                      Icons.people_outline,
                      AppTheme.primaryColor,
                      'Approved: $approvedUsers',
                      () => onNavigateToTab?.call(1),
                    ),
                    _buildGridCard(
                      context,
                      'Pending Complaints',
                      pendingComplaints.toString(),
                      Icons.report_problem_outlined,
                      AppTheme.accentColor,
                      'Resolved: $resolvedComplaints',
                      () => onNavigateToTab?.call(2),
                    ),
                    _buildGridCard(
                      context,
                      'Security Staff',
                      securityStaff.toString(),
                      Icons.security_outlined,
                      AppTheme.secondaryColor,
                      'Active Personnel',
                      () => onNavigateToTab?.call(3),
                    ),
                    _buildGridCard(
                      context,
                      'Total Complaints',
                      totalComplaints.toString(),
                      Icons.list_alt_outlined,
                      AppTheme.errorColor,
                      'All Time',
                      () => onNavigateToTab?.call(2),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.08),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Value
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitle
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppTheme.textColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textColor.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TenantsTab extends StatelessWidget {
  const _TenantsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManagerBloc, ManagerState>(
      builder: (context, state) {
        if (state is ManagerLoaded) {
          final tenants = state.users.where((u) => u.userType == UserType.user).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      tenant.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(tenant.name),
                  subtitle: Text(tenant.email),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tenant.status == AccountStatus.approved
                          ? AppTheme.secondaryColor
                          : AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tenant.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () => _showTenantDetails(context, tenant),
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _showTenantDetails(BuildContext context, UserModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tenant.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${tenant.email}'),
              Text('Mobile: ${tenant.mobileNumber}'),
              Text('Status: ${tenant.status.name}'),
              if (tenant.block != null) Text('Block: ${tenant.block}'),
            ],
          ),
        ),
        actions: [
          if (tenant.status == AccountStatus.pending)
            ElevatedButton(
              onPressed: () {
                context.read<ManagerBloc>().add(
                      UpdateUserStatusEvent(
                        userId: tenant.id,
                        status: AccountStatus.approved,
                      ),
                    );
                Navigator.pop(context);
              },
              child: const Text('Approve'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ComplaintsTab extends StatelessWidget {
  const _ComplaintsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManagerBloc, ManagerState>(
      builder: (context, state) {
        if (state is ManagerLoaded) {
          final complaints = state.complaints;
          if (complaints.isEmpty) {
            return const Center(child: Text('No complaints'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(complaint.status),
                    child: Icon(
                      _getStatusIcon(complaint.status),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(complaint.type.name.toUpperCase()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complaint.description),
                      const SizedBox(height: 4),
                      Text('By: ${complaint.userName}'),
                      Text('Status: ${complaint.status.name}'),
                    ],
                  ),
                  trailing: PopupMenuButton<ComplaintStatus>(
                    onSelected: (value) {
                      context.read<ManagerBloc>().add(
                            UpdateComplaintStatusEvent(
                              complaintId: complaint.id,
                              status: value,
                            ),
                          );
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<ComplaintStatus>(
                        value: ComplaintStatus.inProgress,
                        child: Text('Mark In Progress'),
                      ),
                      const PopupMenuItem<ComplaintStatus>(
                        value: ComplaintStatus.resolved,
                        child: Text('Mark Resolved'),
                      ),
                      const PopupMenuItem<ComplaintStatus>(
                        value: ComplaintStatus.rejected,
                        child: Text('Reject'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return AppTheme.accentColor;
      case ComplaintStatus.inProgress:
        return AppTheme.primaryColor;
      case ComplaintStatus.resolved:
        return AppTheme.secondaryColor;
      case ComplaintStatus.rejected:
        return AppTheme.errorColor;
    }
  }

  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.pending;
      case ComplaintStatus.inProgress:
        return Icons.work;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
    }
  }
}

class _SecurityTab extends StatelessWidget {
  const _SecurityTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManagerBloc, ManagerState>(
      builder: (context, state) {
        if (state is ManagerLoaded) {
          final security = state.users.where((u) => u.userType == UserType.security).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: security.length,
            itemBuilder: (context, index) {
              final sec = security[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      sec.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(sec.name),
                  subtitle: Text(sec.email),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sec.status == AccountStatus.approved
                          ? AppTheme.secondaryColor
                          : AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sec.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

