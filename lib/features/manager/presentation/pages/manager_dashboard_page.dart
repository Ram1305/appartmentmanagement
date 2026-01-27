import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/models/event_model.dart';
import '../../../../core/models/block_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/manager_bloc.dart';
import '../../../admin/presentation/pages/widgets/add_event_dialog.dart';

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
        title: const Text(
          'Manager Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
          const _EventsTab(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
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
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your apartment complex efficiently',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                // Grid View - 2x2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Value
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: AppTheme.textColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
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
          final pendingTenants = tenants.where((t) => t.status == AccountStatus.pending).toList();
          final approvedTenants = tenants.where((t) => t.status == AccountStatus.approved).toList();
          
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 13),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Pending'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${pendingTenants.length}',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Approved'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${approvedTenants.length}',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TenantList(tenants: pendingTenants, isPending: true),
                      _TenantList(tenants: approvedTenants, isPending: false),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _TenantList extends StatelessWidget {
  final List<UserModel> tenants;
  final bool isPending;

  const _TenantList({required this.tenants, required this.isPending});

  @override
  Widget build(BuildContext context) {
    if (tenants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.pending_actions : Icons.check_circle_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              isPending ? 'No pending tenants' : 'No approved tenants',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      itemCount: tenants.length,
      itemBuilder: (context, index) {
        final tenant = tenants[index];
        return _TenantCard(tenant: tenant, isPending: isPending);
      },
    );
  }
}

class _TenantCard extends StatelessWidget {
  final UserModel tenant;
  final bool isPending;

  const _TenantCard({required this.tenant, required this.isPending});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: tenant.profilePic != null && tenant.profilePic!.isNotEmpty
                  ? NetworkImage(tenant.profilePic!)
                  : null,
              child: tenant.profilePic == null || tenant.profilePic!.isEmpty
                  ? Text(
                      tenant.name[0].toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name, Email, Mobile
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tenant.email,
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        tenant.mobileNumber,
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  if (tenant.block != null && tenant.floor != null && tenant.roomNumber != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.home, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Block ${tenant.block}, Floor ${tenant.floor}, Room ${tenant.roomNumber}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Status Badge and Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tenant.status == AccountStatus.approved
                        ? AppTheme.secondaryColor
                        : AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tenant.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  iconSize: 18,
                  icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[700]),
                  itemBuilder: (context) {
                    final items = <PopupMenuItem<String>>[];
                    if (isPending) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: AppTheme.secondaryColor),
                              SizedBox(width: 8),
                              Text('Approve', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                    items.addAll([
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: AppTheme.errorColor),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ]);
                    return items;
                  },
                  onSelected: (value) {
                    if (value == 'approve') {
                      _showApprovalDialog(context, tenant);
                    } else if (value == 'edit') {
                      _showEditDialog(context, tenant);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, tenant);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, UserModel tenant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ApprovalBottomSheet(tenant: tenant),
    );
  }

  void _showEditDialog(BuildContext context, UserModel tenant) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _showDeleteDialog(BuildContext context, UserModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Tenant',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${tenant.name}? This action cannot be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete functionality coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 13)),
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
            return Center(
              child: Text(
                'No complaints',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 80,
            ),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: _getStatusColor(complaint.status),
                    child: Icon(
                      _getStatusIcon(complaint.status),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    complaint.type.name.toUpperCase(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        complaint.description,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By: ${complaint.userName}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        'Status: ${complaint.status.name}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<ComplaintStatus>(
                    iconSize: 20,
                    itemBuilder: (context) => [
                      const PopupMenuItem<ComplaintStatus>(
                        value: ComplaintStatus.inProgress,
                        child: Text('Mark In Progress', style: TextStyle(fontSize: 13)),
                      ),
                      const PopupMenuItem<ComplaintStatus>(
                        value: ComplaintStatus.resolved,
                        child: Text('Mark Resolved', style: TextStyle(fontSize: 13)),
                      ),
                      const PopupMenuItem<ComplaintStatus>(
                        value: ComplaintStatus.rejected,
                        child: Text('Reject', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onSelected: (value) {
                      context.read<ManagerBloc>().add(
                            UpdateComplaintStatusEvent(
                              complaintId: complaint.id,
                              status: value,
                            ),
                          );
                    },
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
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 80,
            ),
            itemCount: security.length,
            itemBuilder: (context, index) {
              final sec = security[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      sec.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  title: Text(
                    sec.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    sec.email,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sec.status == AccountStatus.approved
                          ? AppTheme.secondaryColor
                          : AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sec.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
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

class _EventsTab extends StatefulWidget {
  const _EventsTab();

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  final ApiService _apiService = ApiService();
  List<EventModel> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAllNotices(type: 'event');
      if (response['success'] == true && response['notices'] != null) {
        setState(() {
          _events = (response['notices'] as List)
              .map((e) => EventModel.fromJson(e))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addEvent(String title, String subtitle, String content, DateTime eventDate) async {
    try {
      final response = await _apiService.createNotice(
        title: title,
        subtitle: subtitle.isEmpty ? null : subtitle,
        content: content,
        type: 'event',
        targetAudience: 'all',
        eventDate: eventDate.toIso8601String(),
      );
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event added successfully')),
          );
          _loadEvents();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Failed to add event')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Events',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () {
                    AddEventDialog.show(context, _addEvent);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add Event',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No events yet', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.event, color: AppTheme.primaryColor),
                        ),
                        title: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (event.subtitle != null && event.subtitle!.isNotEmpty)
                              Text(
                                event.subtitle!,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            if (event.subtitle != null && event.subtitle!.isNotEmpty)
                              const SizedBox(height: 4),
                            Text(
                              event.content,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    event.eventDate.toString().split(' ')[0],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ApprovalBottomSheet extends StatefulWidget {
  final UserModel tenant;

  const _ApprovalBottomSheet({required this.tenant});

  @override
  State<_ApprovalBottomSheet> createState() => _ApprovalBottomSheetState();
}

class _ApprovalBottomSheetState extends State<_ApprovalBottomSheet> {
  final ApiService _apiService = ApiService();
  final formKey = GlobalKey<FormState>();
  
  List<BlockModel> _blocks = [];
  bool _isLoading = true;
  
  BlockModel? _selectedBlock;
  FloorModel? _selectedFloor;
  RoomModel? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  Future<void> _loadBlocks() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAllBlocks();
      if (response['success'] == true && response['blocks'] != null) {
        setState(() {
          _blocks = (response['blocks'] as List)
              .map((b) => BlockModel.fromJson(b))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blocks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            const Text(
              'Approve Tenant',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Assign room details for ${widget.tenant.name}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Block Dropdown
              DropdownButtonFormField<BlockModel>(
                value: _selectedBlock,
                decoration: const InputDecoration(
                  labelText: 'Block *',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black),
                dropdownColor: Colors.white,
                items: _blocks.map((block) {
                  return DropdownMenuItem<BlockModel>(
                    value: block,
                    child: Text('Block ${block.name}', style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (BlockModel? value) {
                  setState(() {
                    _selectedBlock = value;
                    _selectedFloor = null;
                    _selectedRoom = null;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a block';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Floor Dropdown
              DropdownButtonFormField<FloorModel>(
                value: _selectedFloor,
                decoration: const InputDecoration(
                  labelText: 'Floor *',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black),
                dropdownColor: Colors.white,
                items: _selectedBlock?.floors.map((floor) {
                  return DropdownMenuItem<FloorModel>(
                    value: floor,
                    child: Text('Floor ${floor.number}', style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: _selectedBlock == null
                    ? null
                    : (FloorModel? value) {
                        setState(() {
                          _selectedFloor = value;
                          _selectedRoom = null;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a floor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Room Number Dropdown
              DropdownButtonFormField<RoomModel>(
                value: _selectedRoom,
                decoration: const InputDecoration(
                  labelText: 'Room Number *',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black),
                dropdownColor: Colors.white,
                items: _selectedFloor?.rooms.map((room) {
                  return DropdownMenuItem<RoomModel>(
                    value: room,
                    child: Text('Room ${room.number} (${room.type})', style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: _selectedFloor == null
                    ? null
                    : (RoomModel? value) {
                        setState(() {
                          _selectedRoom = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a room';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          context.read<ManagerBloc>().add(
                                UpdateUserStatusEvent(
                                  userId: widget.tenant.id,
                                  status: AccountStatus.approved,
                                  block: _selectedBlock!.name,
                                  floor: _selectedFloor!.number,
                                  roomNumber: _selectedRoom!.number,
                                ),
                              );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tenant approved and room assigned successfully. Room is now occupied.'),
                              backgroundColor: AppTheme.secondaryColor,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Approve', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

