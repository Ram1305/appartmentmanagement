import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/visitor_model.dart';
import '../bloc/user_bloc.dart';
import 'visitor_details_page.dart';

class GateApprovalPage extends StatefulWidget {
  const GateApprovalPage({super.key});

  @override
  State<GateApprovalPage> createState() => _GateApprovalPageState();
}

class _GateApprovalPageState extends State<GateApprovalPage> {
  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Approval'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is! UserLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final pending = state.myUnitVisitors
              .where((v) => v.approvalStatus == VisitorApprovalStatus.pending)
              .toList();
          if (pending.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.textColor.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No visitors waiting for approval',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final visitor = pending[index];
                return _GateApprovalCard(
                  visitor: visitor,
                  formatDateTime: _formatDateTime,
                  onApprove: () => _approve(context, visitor),
                  onReject: () => _reject(context, visitor),
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisitorDetailsPage(visitor: visitor),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _approve(BuildContext context, VisitorModel visitor) {
    context.read<UserBloc>().add(
          UpdateVisitorApprovalEvent(visitorId: visitor.id, status: 'approved'),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${visitor.name} approved'),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
  }

  void _reject(BuildContext context, VisitorModel visitor) {
    context.read<UserBloc>().add(
          UpdateVisitorApprovalEvent(visitorId: visitor.id, status: 'rejected'),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${visitor.name} rejected'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
  }
}

class _GateApprovalCard extends StatelessWidget {
  final VisitorModel visitor;
  final String Function(DateTime) formatDateTime;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const _GateApprovalCard({
    required this.visitor,
    required this.formatDateTime,
    required this.onApprove,
    required this.onReject,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                  child: visitor.image != null && visitor.image!.isNotEmpty
                      ? ClipOval(
                          child: visitor.image!.startsWith('http')
                              ? Image.network(
                                  visitor.image!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.person, color: AppTheme.primaryColor),
                                )
                              : Icon(Icons.person, color: AppTheme.primaryColor),
                        )
                      : Icon(Icons.person, size: 28, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${visitor.type.displayName} • Block ${visitor.block}-${visitor.homeNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textColor.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        formatDateTime(visitor.visitTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
