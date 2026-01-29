import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/app_theme.dart';
import '../../../../../../core/models/complaint_model.dart';
import '../../../../../../core/services/api_service.dart';

class AdminComplaintsTab extends StatefulWidget {
  const AdminComplaintsTab({super.key});

  @override
  State<AdminComplaintsTab> createState() => _AdminComplaintsTabState();
}

class _AdminComplaintsTabState extends State<AdminComplaintsTab>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  List<ComplaintModel> _complaints = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadComplaints();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      _loadComplaints();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String get _currentStatusFilter =>
      _tabController.index == 0 ? 'pending' : 'completed';

  Future<void> _loadComplaints() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getComplaints(status: _currentStatusFilter);
      if (mounted) {
        if (res['success'] == true) {
          final list = (res['complaints'] as List?)
                  ?.map((e) =>
                      ComplaintModel.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList() ??
              [];
          setState(() {
            _complaints = list;
            _loading = false;
          });
        } else {
          setState(() {
            _error = res['error']?.toString() ?? 'Failed to load complaints';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textColor.withOpacity(0.7),
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _complaints.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null && _complaints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadComplaints,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_problem_outlined,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'No pending complaints'
                  : 'No completed complaints',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _complaints.length,
        itemBuilder: (context, index) {
          final complaint = _complaints[index];
          final isPendingTab = _tabController.index == 0;
          return _AdminComplaintCard(
            complaint: complaint,
            showUpdateButton: isPendingTab,
            onStatusUpdated: _loadComplaints,
          );
        },
      ),
    );
  }
}

class _AdminComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool showUpdateButton;
  final VoidCallback onStatusUpdated;

  const _AdminComplaintCard({
    required this.complaint,
    required this.showUpdateButton,
    required this.onStatusUpdated,
  });

  Color _statusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return AppTheme.accentColor;
      case ComplaintStatus.approved:
        return AppTheme.primaryColor;
      case ComplaintStatus.completed:
        return AppTheme.secondaryColor;
      case ComplaintStatus.cancelled:
        return AppTheme.errorColor;
    }
  }

  String _roomDetails() {
    final parts = <String>[];
    if (complaint.block != null && complaint.block!.isNotEmpty) {
      parts.add('Block ${complaint.block}');
    }
    if (complaint.floor != null && complaint.floor!.isNotEmpty) {
      parts.add('Floor ${complaint.floor}');
    }
    if (complaint.roomNumber != null && complaint.roomNumber!.isNotEmpty) {
      parts.add('Room ${complaint.roomNumber}');
    }
    return parts.isEmpty ? '—' : parts.join(' • ');
  }

  Future<void> _showUpdateStatusDialog(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Update status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              ...ComplaintStatus.values.map((status) {
                return ListTile(
                  title: Text(
                    status.name[0].toUpperCase() + status.name.substring(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, status.name),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    final api = ApiService();
    final res = await api.updateComplaintStatus(complaint.id, chosen);
    if (context.mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${chosen}'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        onStatusUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error']?.toString() ?? 'Failed to update status'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(complaint.createdAt);
    final shortDesc = complaint.description.length > 80
        ? '${complaint.description.substring(0, 80)}...'
        : complaint.description;
    final statusColor = _statusColor(complaint.status);
    final resident =
        '${complaint.userName} • ${_roomDetails()}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resident,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    complaint.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              complaint.type.name.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              shortDesc,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textColor.withOpacity(0.85),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (showUpdateButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showUpdateStatusDialog(context),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Update status'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
