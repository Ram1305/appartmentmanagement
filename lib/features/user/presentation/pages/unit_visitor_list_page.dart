import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/visitor_model.dart';
import '../bloc/user_bloc.dart';
import 'visitor_details_page.dart';

/// Shows visitors for the resident's unit filtered by type (e.g. Cab/Auto or Allowed Delivery).
/// These are visitors that security has added for this unit.
class UnitVisitorListPage extends StatefulWidget {
  final String title;
  final List<VisitorType> visitorTypes;

  const UnitVisitorListPage({
    super.key,
    required this.title,
    required this.visitorTypes,
  });

  @override
  State<UnitVisitorListPage> createState() => _UnitVisitorListPageState();
}

class _UnitVisitorListPageState extends State<UnitVisitorListPage> {
  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is! UserLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
          final filtered = state.myUnitVisitors
              .where((v) => widget.visitorTypes.contains(v.type))
              .toList();
          if (filtered.isEmpty) {
            return _EmptyState(
              title: widget.title,
              onRefresh: () {
                context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
            },
            color: AppTheme.primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final visitor = filtered[index];
                return _VisitorCard(
                  visitor: visitor,
                  formatDateTime: _formatDateTime,
                  formatTimeAgo: _formatTimeAgo,
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VisitorDetailsPage(visitor: visitor),
                      ),
                    );
                  },
                  onApprove: visitor.approvalStatus == VisitorApprovalStatus.pending
                      ? () => _approve(context, visitor)
                      : null,
                  onReject: visitor.approvalStatus == VisitorApprovalStatus.pending
                      ? () => _reject(context, visitor)
                      : null,
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('${visitor.name} approved'),
            ],
          ),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
    }
  }

  void _reject(BuildContext context, VisitorModel visitor) {
    context.read<UserBloc>().add(
          UpdateVisitorApprovalEvent(visitorId: visitor.id, status: 'rejected'),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('${visitor.name} rejected'),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;

  const _EmptyState({required this.title, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title.toLowerCase().contains('cab') || title.toLowerCase().contains('auto')
                  ? Icons.local_taxi_rounded
                  : Icons.delivery_dining_rounded,
              size: 72,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No ${title.toLowerCase()} yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'When security adds a $title for your unit, it will show up here.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.65),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.6)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  final VisitorModel visitor;
  final String Function(DateTime) formatDateTime;
  final String Function(DateTime) formatTimeAgo;
  final VoidCallback onViewDetails;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _VisitorCard({
    required this.visitor,
    required this.formatDateTime,
    required this.formatTimeAgo,
    required this.onViewDetails,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = visitor.approvalStatus == VisitorApprovalStatus.pending;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.06),
                    AppTheme.primaryColor.withOpacity(0.02),
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: visitor.image != null && visitor.image!.isNotEmpty
                        ? ClipOval(
                            child: visitor.image!.startsWith('http')
                                ? Image.network(
                                    visitor.image!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _avatarIcon(),
                                  )
                                : _avatarIcon(),
                          )
                        : _avatarIcon(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                visitor.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textColor,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? AppTheme.accentColor.withOpacity(0.15)
                                    : AppTheme.secondaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPending
                                    ? formatTimeAgo(visitor.visitTime)
                                    : 'Approved',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isPending
                                      ? AppTheme.accentColor.withOpacity(0.9)
                                      : AppTheme.secondaryColor.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.badge_outlined,
                                size: 14,
                                color: AppTheme.textColor.withOpacity(0.55)),
                            const SizedBox(width: 4),
                            Text(
                              visitor.type.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textColor.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 14,
                                color: AppTheme.textColor.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(
                              formatDateTime(visitor.visitTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textColor.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                        if (visitor.vehicleNumber != null &&
                            visitor.vehicleNumber!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.directions_car_outlined,
                                  size: 14,
                                  color: AppTheme.textColor.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Text(
                                visitor.vehicleNumber!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                      color: AppTheme.dividerColor.withOpacity(0.8)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.visibility_rounded,
                      label: 'Details',
                      color: AppTheme.primaryColor,
                      onTap: onViewDetails,
                      outlined: true,
                    ),
                  ),
                  if (onReject != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.cancel_rounded,
                        label: 'Reject',
                        color: AppTheme.errorColor,
                        onTap: onReject!,
                        outlined: true,
                      ),
                    ),
                  ],
                  if (onApprove != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.check_circle_rounded,
                        label: 'Approve',
                        color: AppTheme.secondaryColor,
                        onTap: onApprove!,
                        filled: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarIcon() {
    return Icon(Icons.person_rounded,
        size: 32, color: AppTheme.primaryColor.withOpacity(0.7));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: outlined
                ? Border.all(color: color.withOpacity(0.5))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
