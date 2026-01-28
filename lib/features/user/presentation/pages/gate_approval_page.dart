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
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            // expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              // titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text(
                'Gate Approval',
                style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700,

                  fontSize: 20,

                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.85),
                      const Color(0xFF0F2D6E),
                    ],
                  ),
                ),
              ),
            ),
          ),
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is! UserLoaded) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                );
              }
              final pending = state.myUnitVisitors
                  .where((v) => v.approvalStatus == VisitorApprovalStatus.pending)
                  .toList();
              if (pending.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(onRefresh: () {
                    context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
                  }),
                );
              }
              return SliverToBoxAdapter(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
                  },
                  color: AppTheme.primaryColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pending_actions_rounded,
                                    size: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${pending.length} waiting',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Swipe down to refresh',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: pending.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final visitor = pending[index];
                          return _GateApprovalCard(
                            visitor: visitor,
                            formatDateTime: _formatDateTime,
                            formatTimeAgo: _formatTimeAgo,
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
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _approve(BuildContext context, VisitorModel visitor) {
    context.read<UserBloc>().add(
          UpdateVisitorApprovalEvent(visitorId: visitor.id, status: 'approved'),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text('${visitor.name} approved'),
          ],
        ),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        content: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text('${visitor.name} rejected'),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    context.read<UserBloc>().add(LoadMyUnitVisitorsEvent());
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.how_to_reg_rounded,
                size: 72,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'All clear',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No visitors are waiting for your approval right now. You\'ll see requests here when someone arrives at the gate.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppTheme.textColor.withOpacity(0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.6)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GateApprovalCard extends StatelessWidget {
  final VisitorModel visitor;
  final String Function(DateTime) formatDateTime;
  final String Function(DateTime) formatTimeAgo;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const _GateApprovalCard({
    required this.visitor,
    required this.formatDateTime,
    required this.formatTimeAgo,
    required this.onApprove,
    required this.onReject,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
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
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
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
                                      errorBuilder: (_, __, ___) => _avatarIcon(),
                                    )
                                  : _avatarIcon(),
                            )
                          : _avatarIcon(),
                    ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                formatTimeAgo(visitor.visitTime),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentColor.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 14, color: AppTheme.textColor.withOpacity(0.55)),
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
                            Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textColor.withOpacity(0.5)),
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
                        if (visitor.reasonForVisit != null && visitor.reasonForVisit!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          //   decoration: BoxDecoration(
                          //     color: AppTheme.backgroundColor,
                          //     borderRadius: BorderRadius.circular(10),
                          //   ),
                          //   child: Row(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textColor.withOpacity(0.5)),
                          //       const SizedBox(width: 6),
                          //       Expanded(
                          //         child: Text(
                          //           visitor.reasonForVisit!,
                          //           style: TextStyle(
                          //             fontSize: 12,
                          //             color: AppTheme.textColor.withOpacity(0.7),
                          //           ),
                          //           maxLines: 2,
                          //           overflow: TextOverflow.ellipsis,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        // ],
                        // if (visitor.vehicleNumber != null && visitor.vehicleNumber!.isNotEmpty) ...[
                        //   const SizedBox(height: 4),
                        //   Row(
                        //     children: [
                        //       Icon(Icons.directions_car_outlined, size: 14, color: AppTheme.textColor.withOpacity(0.5)),
                        //       const SizedBox(width: 4),
                        //       Text(
                        //         visitor.vehicleNumber!,
                        //         style: TextStyle(
                        //           fontSize: 12,
                        //           color: AppTheme.textColor.withOpacity(0.6),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
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
                  top: BorderSide(color: AppTheme.dividerColor.withOpacity(0.8)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.visibility_rounded,
                      label: '',
                      color: AppTheme.primaryColor,
                      onTap: onViewDetails,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.cancel_rounded,
                      label: '',
                      color: AppTheme.errorColor,
                      onTap: onReject,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    // flex: 2,
                    child: _ActionButton(
                      icon: Icons.check_circle_rounded,
                      label: '',
                      color: AppTheme.secondaryColor,
                      onTap: onApprove,
                      filled: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarIcon() {
    return Icon(Icons.person_rounded, size: 32, color: AppTheme.primaryColor.withOpacity(0.7));
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
            border: outlined ? Border.all(color: color.withOpacity(0.5)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
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
          ),
        ),
      ),
    );
  }
}
