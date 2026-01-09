import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/app_theme.dart';
import '../../../../../../core/models/complaint_model.dart';
import '../../bloc/user_bloc.dart';
import 'raise_complaint_dialog.dart';

class ComplaintsTab extends StatelessWidget {
  final String userId;

  const ComplaintsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoaded) {
            final complaints = state.complaints
                .where((c) => c.userId == userId)
                .toList();
            
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_view), text: 'Categories'),
                      Tab(icon: Icon(Icons.list), text: 'My Complaints'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Categories Grid View
                        _buildCategoryGrid(),
                        // Complaints List View
                        complaints.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.report_problem_outlined,
                                      size: 48,
                                      color: AppTheme.textColor.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No complaints yet',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textColor.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => _showRaiseComplaintDialog(context, null),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Raise Complaint', style: TextStyle(fontSize: 13)),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getStatusColor(complaint.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getStatusIcon(complaint.status),
                            color: _getStatusColor(complaint.status),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(complaint.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  complaint.type.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(complaint.status),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                complaint.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(complaint.status),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      complaint.status.name.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: AppTheme.textColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    complaint.createdAt.toString().split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                              },
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
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

  void _showRaiseComplaintDialog(BuildContext context, ComplaintType? type) {
    showDialog(
      context: context,
      builder: (context) => RaiseComplaintDialog(userId: userId, initialType: type),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'type': ComplaintType.plumbing, 'icon': Icons.plumbing, 'label': 'Plumbing', 'color': Colors.blue},
      {'type': ComplaintType.electrical, 'icon': Icons.electrical_services, 'label': 'Electrical', 'color': Colors.orange},
      {'type': ComplaintType.cleaning, 'icon': Icons.cleaning_services, 'label': 'Cleaning', 'color': Colors.green},
      {'type': ComplaintType.maintenance, 'icon': Icons.build, 'label': 'Maintenance', 'color': Colors.purple},
      {'type': ComplaintType.security, 'icon': Icons.security, 'label': 'Security', 'color': Colors.red},
      {'type': ComplaintType.other, 'icon': Icons.more_horiz, 'label': 'Others', 'color': Colors.grey},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () => _showRaiseComplaintDialog(context, category['type'] as ComplaintType),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    size: 26,
                    color: category['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

