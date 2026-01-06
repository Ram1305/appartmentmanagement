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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRaiseComplaintDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoaded) {
            final complaints = state.complaints
                .where((c) => c.userId == userId)
                .toList();
            if (complaints.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.report_problem_outlined,
                      size: 64,
                      color: AppTheme.textColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No complaints yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showRaiseComplaintDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Raise Complaint'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getStatusColor(complaint.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getStatusIcon(complaint.status),
                            color: _getStatusColor(complaint.status),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(complaint.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  complaint.type.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(complaint.status),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                complaint.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(complaint.status),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      complaint.status.name.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppTheme.textColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    complaint.createdAt.toString().split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 12,
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

  void _showRaiseComplaintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RaiseComplaintDialog(userId: userId),
    );
  }
}

