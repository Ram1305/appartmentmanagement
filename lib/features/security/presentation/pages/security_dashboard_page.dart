import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import '../../../../core/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/models/visitor_model.dart';
import '../../../../core/models/block_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/security_bloc.dart';

class SecurityDashboardPage extends StatefulWidget {
  const SecurityDashboardPage({super.key});

  @override
  State<SecurityDashboardPage> createState() => _SecurityDashboardPageState();
}

enum _VisitorListSection { waitingApproval, today, upcoming, viewAll }

class _SecurityDashboardPageState extends State<SecurityDashboardPage> {
  _VisitorListSection _activeSection = _VisitorListSection.viewAll;

  @override
  void initState() {
    super.initState();
    context.read<SecurityBloc>().add(LoadSecurityDataEvent());
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<VisitorModel> _filteredVisitors(SecurityLoaded state) {
    final now = DateTime.now();
    switch (_activeSection) {
      case _VisitorListSection.waitingApproval:
        return state.visitors.where((v) => v.approvalStatus == VisitorApprovalStatus.pending).toList();
      case _VisitorListSection.today:
        // Use local date so "today" is correct regardless of server UTC
        return state.visitors.where((v) => _isSameDay(v.visitTime.toLocal(), now)).toList();
      case _VisitorListSection.upcoming:
        return state.visitors.where((v) => v.visitTime.isAfter(now)).toList();
      case _VisitorListSection.viewAll:
        return state.visitors;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
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
      body: BlocConsumer<SecurityBloc, SecurityState>(
        listener: (context, state) {
          if (state is SecurityLoaded && state.lastAddVisitorError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.lastAddVisitorError!),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<SecurityBloc>().add(ClearSecurityErrorEvent());
          }
        },
        builder: (context, state) {
          if (state is SecurityLoaded) {
            final filtered = _filteredVisitors(state);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      _GridCard(
                        icon: Icons.person_add,
                        label: 'Add Visitor',
                        onTap: () => _showAddVisitorSheet(context, state.blocks),
                      ),
                      _GridCard(
                        icon: Icons.pending_actions,
                        label: 'Waiting for Approval',
                        onTap: () => _showWaitingForApprovalSheet(context, state.visitors),
                      ),
                      _GridCard(
                        icon: Icons.today,
                        label: "Today's Visitors",
                        onTap: () => setState(() => _activeSection = _VisitorListSection.today),
                        isSelected: _activeSection == _VisitorListSection.today,
                      ),
                      _GridCard(
                        icon: Icons.upcoming,
                        label: 'Upcoming Visitors',
                        onTap: () => _showUpcomingVisitorsSheet(context, state.visitors),
                      ),
                      _GridCard(
                        icon: Icons.visibility,
                        label: 'View Visitor',
                        onTap: () => setState(() => _activeSection = _VisitorListSection.viewAll),
                        isSelected: _activeSection == _VisitorListSection.viewAll,
                      ),
                      _GridCard(
                        icon: Icons.verified_user,
                        label: 'Verify Visitor',
                        onTap: () => _showVerifyVisitorSheet(context, state.visitors),
                      ),
                    ],
                  ),
                ),
                if (filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, color: AppTheme.primaryColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${filtered.length} visitor${filtered.length == 1 ? "" : "s"}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search, size: 48, color: AppTheme.textColor.withOpacity(0.25)),
                              const SizedBox(height: 12),
                              Text(
                                _activeSection == _VisitorListSection.waitingApproval
                                    ? 'No visitors waiting for approval'
                                    : _activeSection == _VisitorListSection.today
                                        ? 'No visitors today'
                                        : _activeSection == _VisitorListSection.upcoming
                                            ? 'No upcoming visitors'
                                            : 'No visitors registered',
                                style: TextStyle(fontSize: 13, color: AppTheme.textColor.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final visitor = filtered[index];
                            final vt = visitor.visitTime.toLocal();
                            final timeStr = '${vt.hour.toString().padLeft(2, '0')}:${vt.minute.toString().padLeft(2, '0')}';
                            final dateStr = '${vt.day}/${vt.month}/${vt.year}';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.dividerColor.withOpacity(0.8)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: visitor.image != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Image.network(visitor.image!, fit: BoxFit.cover),
                                                )
                                              : Icon(Icons.person_rounded, color: AppTheme.primaryColor.withOpacity(0.8), size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      visitor.name,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppTheme.textColor,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (visitor.approvalStatus == VisitorApprovalStatus.pending)
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 6),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.accentColor.withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text('PENDING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.accentColor)),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${visitor.type.displayName} • Block ${visitor.block}-${visitor.homeNumber}',
                                                style: TextStyle(fontSize: 11, color: AppTheme.textColor.withOpacity(0.65)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(Icons.phone_outlined, size: 11, color: AppTheme.textColor.withOpacity(0.5)),
                                                  const SizedBox(width: 3),
                                                  Text(visitor.mobileNumber, style: TextStyle(fontSize: 11, color: AppTheme.textColor.withOpacity(0.6))),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(timeStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor.withOpacity(0.9))),
                                            const SizedBox(height: 1),
                                            Text(dateStr, style: TextStyle(fontSize: 10, color: AppTheme.textColor.withOpacity(0.5))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _showAddVisitorSheet(BuildContext context, List<BlockModel> blocks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, scrollController) => _AddVisitorSheet(
          blocks: blocks,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showWaitingForApprovalSheet(BuildContext context, List<VisitorModel> visitors) {
    final pending = visitors.where((v) => v.approvalStatus == VisitorApprovalStatus.pending).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => _WaitingForApprovalSheet(
          visitors: pending,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showUpcomingVisitorsSheet(BuildContext context, List<VisitorModel> visitors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => _UpcomingVisitorsSheet(
          visitors: visitors.where((v) => v.visitTime.isAfter(DateTime.now())).toList(),
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showVerifyVisitorSheet(BuildContext context, List<VisitorModel> visitors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => _VerifyVisitorSheet(
          visitors: visitors,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _GridCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppTheme.primaryColor.withOpacity(0.15)
          : AppTheme.primaryColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ————— Bottom sheet: Waiting for Approval —————
class _WaitingForApprovalSheet extends StatelessWidget {
  final List<VisitorModel> visitors;
  final ScrollController scrollController;

  const _WaitingForApprovalSheet({
    required this.visitors,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Visitors Waiting for Approval', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: AppTheme.textColor.withOpacity(0.7)), style: IconButton.styleFrom(backgroundColor: AppTheme.dividerColor)),
              ],
            ),
          ),
          Flexible(
            child: visitors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: AppTheme.secondaryColor.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text('No visitors waiting for approval', style: TextStyle(fontSize: 13, color: AppTheme.textColor.withOpacity(0.5))),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: visitors.length,
                    itemBuilder: (context, index) {
                      final v = visitors[index];
                      final vt = v.visitTime.toLocal();
                      final timeStr = '${vt.hour.toString().padLeft(2, '0')}:${vt.minute.toString().padLeft(2, '0')}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accentColor.withOpacity(0.25)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: v.image != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(v.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: AppTheme.primaryColor.withOpacity(0.8), size: 24)))
                                  : Icon(Icons.person_rounded, color: AppTheme.primaryColor.withOpacity(0.8), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(v.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                                  const SizedBox(height: 2),
                                  Text('Block ${v.block}-${v.homeNumber} • ${v.type.displayName}', style: TextStyle(fontSize: 11, color: AppTheme.textColor.withOpacity(0.65))),
                                  const SizedBox(height: 2),
                                  Text(timeStr, style: TextStyle(fontSize: 11, color: AppTheme.textColor.withOpacity(0.5))),
                                ],
                              ),
                            ),
                            Material(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  context.read<SecurityBloc>().add(ApproveVisitorEvent(visitorId: v.id));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${v.name} approved'), backgroundColor: AppTheme.secondaryColor, behavior: SnackBarBehavior.floating));
                                  Navigator.pop(context);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ————— Bottom sheet: Upcoming Visitors with date picker —————
class _UpcomingVisitorsSheet extends StatefulWidget {
  final List<VisitorModel> visitors;
  final ScrollController scrollController;

  const _UpcomingVisitorsSheet({required this.visitors, required this.scrollController});

  @override
  State<_UpcomingVisitorsSheet> createState() => _UpcomingVisitorsSheetState();
}

class _UpcomingVisitorsSheetState extends State<_UpcomingVisitorsSheet> {
  DateTime _selectedDate = DateTime.now();

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<VisitorModel> get _forDate => widget.visitors.where((v) => _isSameDay(v.visitTime, _selectedDate)).toList();

  @override
  Widget build(BuildContext context) {
    final forDate = _forDate;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upcoming Visitors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: AppTheme.textColor.withOpacity(0.7)), style: IconButton.styleFrom(backgroundColor: AppTheme.dividerColor)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate.isBefore(DateTime.now()) ? DateTime.now() : _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.12), AppTheme.secondaryColor.withOpacity(0.06)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.calendar_month, color: AppTheme.primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select date', style: TextStyle(fontSize: 12, color: AppTheme.textColor.withOpacity(0.6), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppTheme.textColor.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.people_outline, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('${forDate.length} visitor${forDate.length == 1 ? "" : "s"} on this date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: forDate.isEmpty
                ? Center(child: Text('No visitors on selected date', style: TextStyle(fontSize: 13, color: AppTheme.textColor.withOpacity(0.5))))
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: forDate.length,
                    itemBuilder: (context, index) {
                      final v = forDate[index];
                      final vt = v.visitTime.toLocal();
                      final timeStr = '${vt.hour.toString().padLeft(2, '0')}:${vt.minute.toString().padLeft(2, '0')}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor.withOpacity(0.8)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: v.image != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(v.image!, fit: BoxFit.cover))
                                  : Icon(Icons.person_rounded, color: AppTheme.primaryColor.withOpacity(0.8), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(v.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                                  const SizedBox(height: 2),
                                  Text('${v.type.displayName} • Block ${v.block}-${v.homeNumber}', style: TextStyle(fontSize: 11, color: AppTheme.textColor.withOpacity(0.65))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(timeStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor.withOpacity(0.9))),
                                if (v.approvalStatus == VisitorApprovalStatus.pending)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                      child: Text('PENDING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.accentColor)),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ————— Bottom sheet: Verify Visitor (OTP or Scan QR) —————
class _VerifyVisitorSheet extends StatefulWidget {
  final List<VisitorModel> visitors;
  final ScrollController scrollController;

  const _VerifyVisitorSheet({required this.visitors, required this.scrollController});

  @override
  State<_VerifyVisitorSheet> createState() => _VerifyVisitorSheetState();
}

class _VerifyVisitorSheetState extends State<_VerifyVisitorSheet> {
  final _otpController = TextEditingController();
  final _visitorIdController = TextEditingController();
  String? _message;
  bool _success = false;
  bool _showScanner = false;
  MobileScannerController? _scannerController;
  bool _scannerLoading = true;
  bool _scannerPermissionGranted = false;
  bool _scannerPermanentlyDenied = false;

  /// Opens scanner UI and initializes camera for QR-only scanning.
  Future<void> _openScanner() async {
    setState(() {
      _showScanner = true;
      _message = null;
      _scannerLoading = true;
      _scannerPermissionGranted = false;
      _scannerPermanentlyDenied = false;
    });
    await _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    if (!mounted) return;
    try {
      var status = await Permission.camera.status;
      if (status.isDenied) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Camera permission required'),
            content: const Text(
              'Camera access is needed to scan visitor QR codes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (shouldRequest != true) {
          status = await Permission.camera.status;
          if (mounted) {
            setState(() {
              _scannerLoading = false;
              _scannerPermissionGranted = false;
              _scannerPermanentlyDenied = status.isPermanentlyDenied;
            });
          }
          return;
        }
        status = await Permission.camera.request();
      }
      if (!mounted) return;
      if (status.isGranted) {
        _scannerController = MobileScannerController(
          formats: [BarcodeFormat.qrCode],
        );
        setState(() {
          _scannerLoading = false;
          _scannerPermissionGranted = true;
          _scannerPermanentlyDenied = false;
        });
      } else {
        setState(() {
          _scannerLoading = false;
          _scannerPermissionGranted = false;
          _scannerPermanentlyDenied = status.isPermanentlyDenied;
        });
        if (status.isPermanentlyDenied && mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Permission required'),
              content: const Text(
                'Please enable camera access in app settings to scan QR codes.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openAppSettings();
                  },
                  child: const Text('Open settings'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scannerLoading = false;
          _scannerPermissionGranted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _scannerPermissionGranted = status.isGranted;
      _scannerPermanentlyDenied = status.isPermanentlyDenied;
    });
    if (status.isGranted && _scannerController == null) {
      _scannerController = MobileScannerController(
        formats: [BarcodeFormat.qrCode],
      );
    } else if (status.isPermanentlyDenied && mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'Please enable camera access in app settings to scan QR codes.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
    }
  }

  void _closeScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      _showScanner = false;
      _scannerLoading = true;
      _scannerPermissionGranted = false;
      _scannerPermanentlyDenied = false;
    });
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _scannerController = null;
    _otpController.dispose();
    _visitorIdController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    final id = _visitorIdController.text.trim();
    final otp = _otpController.text.trim();
    if (id.isEmpty || otp.isEmpty) {
      setState(() { _message = 'Enter visitor ID and OTP'; _success = false; });
      return;
    }
    VisitorModel? visitor;
    for (final v in widget.visitors) {
      if (v.id == id) { visitor = v; break; }
    }
    if (visitor == null) {
      setState(() { _message = 'Visitor not found'; _success = false; });
      return;
    }
    if (visitor.otp != otp) {
      setState(() { _message = 'Invalid OTP'; _success = false; });
      return;
    }
    final name = visitor.name;
    setState(() { _message = 'Verified: $name'; _success = true; });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_message != null) return;
    final list = capture.barcodes;
    if (list.isEmpty) return;
    final code = list.first.rawValue;
    if (code == null || code.isEmpty) return;
    try {
      final map = jsonDecode(code) as Map<String, dynamic>;
      final visitorId = map['visitorId'] as String?;
      final otp = map['otp'] as String?;
      if (visitorId == null || otp == null) {
        setState(() { _message = 'Invalid QR code'; _success = false; });
        return;
      }
      VisitorModel? visitor;
      for (final v in widget.visitors) {
        if (v.id == visitorId) { visitor = v; break; }
      }
      if (visitor == null || visitor.otp != otp) {
        setState(() { _message = 'Visitor not found or OTP mismatch'; _success = false; });
        return;
      }
      final name = visitor.name;
      _scannerController?.dispose();
      _scannerController = null;
      setState(() { _message = 'Verified: $name'; _success = true; _showScanner = false; });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (_) {
      setState(() { _message = 'Invalid QR code'; _success = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showScanner) {
      return Container(
        decoration: BoxDecoration(color: Colors.black, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Scan visitor QR code', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_scannerController != null)
                        IconButton(
                          icon: Icon(
                            _scannerController!.torchEnabled ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: () => _scannerController?.toggleTorch(),
                        ),
                      IconButton(onPressed: _closeScanner, icon: const Icon(Icons.close, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _scannerLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _scannerPermissionGranted && _scannerController != null
                        ? MobileScanner(
                            controller: _scannerController,
                            onDetect: _onQrDetected,
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _scannerPermissionGranted
                                        ? 'Camera could not start'
                                        : 'Camera access is required to scan visitor QR codes.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _requestCameraPermission,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Grant camera permission'),
                                  ),
                                  if (_scannerPermanentlyDenied) ...[
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: openAppSettings,
                                      child: const Text(
                                        'Open settings',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _success ? AppTheme.secondaryColor : AppTheme.errorColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Verify Visitor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: AppTheme.textColor.withOpacity(0.7)), style: IconButton.styleFrom(backgroundColor: AppTheme.dividerColor)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    InkWell(
                      onTap: _openScanner,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.secondaryColor.withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor, size: 32)),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Scan QR code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor)), const SizedBox(height: 4), Text('Open camera to scan visitor\'s QR', style: TextStyle(fontSize: 13, color: AppTheme.textColor.withOpacity(0.6)))])),
                            Icon(Icons.chevron_right, color: AppTheme.textColor.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Or verify with OTP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textColor.withOpacity(0.7))),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _visitorIdController,
                      decoration: InputDecoration(
                        labelText: 'Visitor ID',
                        hintText: 'Enter visitor ID',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'OTP',
                        hintText: '6-digit OTP',
                        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_message != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_message!, style: TextStyle(color: _success ? AppTheme.secondaryColor : AppTheme.errorColor, fontSize: 14, fontWeight: FontWeight.w500))),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _verifyOtp,
                        icon: const Icon(Icons.verified_user, size: 22),
                        label: const Text('Verify OTP'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icons for each visitor type (index matches VisitorType order: cabTaxi..emergency).
const List<IconData> _visitorTypeIcons = [
  Icons.local_taxi,
  Icons.family_restroom,
  Icons.delivery_dining,
  Icons.person,
  Icons.cleaning_services,
  Icons.electrical_services,
  Icons.plumbing,
  Icons.inventory_2,
  Icons.build_circle_outlined,
  Icons.badge_outlined,
  Icons.emergency,
];

class _AddVisitorSheet extends StatefulWidget {
  final List<BlockModel> blocks;
  final ScrollController scrollController;

  const _AddVisitorSheet({
    required this.blocks,
    required this.scrollController,
  });

  @override
  State<_AddVisitorSheet> createState() => _AddVisitorSheetState();
}

class _RoomOption {
  final FloorModel floor;
  final RoomModel room;
  _RoomOption(this.floor, this.room);
  String get label => 'Floor ${floor.number} – ${room.number}';
}

class _AddVisitorSheetState extends State<_AddVisitorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _purposeController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _manualRoomController = TextEditingController();

  BlockModel? _selectedBlock;
  _RoomOption? _selectedRoomOption;
  VisitorType? _selectedType;
  late DateTime _entryTime;
  File? _visitorImage;
  final ImagePicker _picker = ImagePicker();

  List<_RoomOption> get _blockRooms {
    if (_selectedBlock == null) return [];
    final seen = <String>{};
    final list = <_RoomOption>[];
    for (final f in _selectedBlock!.floors) {
      for (final r in f.rooms) {
        final key = '${f.id}_${r.id}';
        if (seen.contains(key)) continue;
        seen.add(key);
        list.add(_RoomOption(f, r));
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _entryTime = DateTime.now();
  }

  @override
  void didUpdateWidget(covariant _AddVisitorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When blocks list updates (e.g. from API), keep selection by id so dropdown value matches an item
    if (_selectedBlock != null && oldWidget.blocks != widget.blocks) {
      final matched = widget.blocks.where((b) => b.id == _selectedBlock!.id).toList();
      final newBlock = matched.isNotEmpty ? matched.first : null;
      _selectedBlock = newBlock;
      // Always clear room when block list or block reference changes so dropdown value stays in items list
      _selectedRoomOption = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _purposeController.dispose();
    _vehicleController.dispose();
    _manualRoomController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _visitorImage = File(image.path);
      });
    }
  }

  String? get _resolvedHomeNumber {
    if (_selectedRoomOption != null) return _selectedRoomOption!.room.number;
    if (_selectedBlock != null && _blockRooms.isEmpty && _manualRoomController.text.trim().isNotEmpty) return _manualRoomController.text.trim();
    return null;
  }

  void _handleAdd() {
    if (_formKey.currentState!.validate() &&
        _selectedBlock != null &&
        _resolvedHomeNumber != null &&
        _selectedType != null) {
      context.read<SecurityBloc>().add(
            AddVisitorEvent(
              name: _nameController.text.trim(),
              mobileNumber: _mobileController.text.trim(),
              type: _selectedType!,
              block: _selectedBlock!.name,
              homeNumber: _resolvedHomeNumber!,
              image: _visitorImage?.path,
              purposeOfVisit: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
              vehicleNumber: _vehicleController.text.trim().isEmpty ? null : _vehicleController.text.trim(),
            ),
          );
      Navigator.pop(context);
    }
  }

  /// Builds room dropdown using a single list for both value and items so Flutter's equality check passes.
  Widget _buildRoomDropdown() {
    final blockRooms = _blockRooms;
    _RoomOption? value;
    if (_selectedRoomOption != null) {
      for (final o in blockRooms) {
        if (o.floor.id == _selectedRoomOption!.floor.id &&
            o.room.id == _selectedRoomOption!.room.id) {
          value = o;
          break;
        }
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<_RoomOption>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Select Room / Flat',
              prefixIcon: Icon(Icons.door_front_door, color: AppTheme.primaryColor, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            ),
            hint: Text(
              blockRooms.isEmpty ? 'No rooms in this block' : 'Choose room',
              style: TextStyle(color: AppTheme.textColor.withOpacity(0.6), fontSize: 16),
            ),
            items: blockRooms.map((opt) {
              return DropdownMenuItem<_RoomOption>(
                value: opt,
                child: Text(opt.label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: blockRooms.isEmpty ? null : (opt) {
              setState(() => _selectedRoomOption = opt);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final entryTimeStr =
        '${_entryTime.day}/${_entryTime.month}/${_entryTime.year} ${_entryTime.hour}:${_entryTime.minute.toString().padLeft(2, '0')}';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Visitor',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppTheme.textColor.withOpacity(0.7)),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.dividerColor,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _buildSectionLabel('Block & Room'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<BlockModel>(
                      value: widget.blocks.isEmpty ? null : _selectedBlock,
                      isExpanded: true,
                      menuMaxHeight: 240,
                      decoration: InputDecoration(
                        labelText: 'Select Block',
                        prefixIcon: Icon(Icons.apartment, color: AppTheme.primaryColor, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                      ),
                      hint: Text(
                        widget.blocks.isEmpty ? 'No blocks loaded' : 'Choose block',
                        style: TextStyle(color: AppTheme.textColor.withOpacity(0.6), fontSize: 16),
                      ),
                      items: widget.blocks.map((block) {
                        return DropdownMenuItem<BlockModel>(
                          value: block,
                          child: Text('Block ${block.name}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: widget.blocks.isEmpty
                          ? null
                          : (block) {
                              setState(() {
                                _selectedBlock = block;
                                _selectedRoomOption = null;
                              });
                            },
                    ),
                  ),
                  if (_selectedBlock != null) ...[
                    _buildRoomDropdown(),
                  ],
                  if (_selectedBlock != null && _blockRooms.isEmpty) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _manualRoomController,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration('Room / Flat number', Icons.door_front_door),
                      validator: (v) {
                        if (_blockRooms.isNotEmpty) return null;
                        return (v == null || v.trim().isEmpty) ? 'Enter room number' : null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionLabel('Visitor Details'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Visitor Name', Icons.person_outline),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter visitor name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Mobile Number', Icons.phone_android),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter mobile number' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Visitor Type'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: visitorTypeDisplayNames.length,
                    itemBuilder: (context, index) {
                      final type = VisitorType.values[index];
                      final selected = _selectedType == type;
                      final icon = index < _visitorTypeIcons.length
                          ? _visitorTypeIcons[index]
                          : Icons.person;
                      return _VisitorTypeTile(
                        icon: icon,
                        label: visitorTypeDisplayNames[index],
                        selected: selected,
                        onTap: () {
                          setState(() {
                            _selectedType = selected ? null : type;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _purposeController,
                    decoration: _inputDecoration('Purpose of Visit (optional)', Icons.edit_note),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: _inputDecoration('Vehicle No. (cab/delivery)', Icons.directions_car_outlined),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.08),
                          AppTheme.secondaryColor.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.access_time, color: AppTheme.primaryColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entry Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textColor.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entryTimeStr,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Photo / ID (optional)'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.12),
                            AppTheme.secondaryColor.withOpacity(0.08),
                          ],
                        ),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _visitorImage != null
                          ? ClipOval(
                              child: Image.file(
                                _visitorImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.add_a_photo, size: 36, color: AppTheme.primaryColor.withOpacity(0.8)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _handleAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                      ),
                      child: const Text('Add Visitor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textColor.withOpacity(0.85),
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _VisitorTypeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VisitorTypeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.18),
                      AppTheme.secondaryColor.withOpacity(0.12),
                    ],
                  )
                : null,
            color: selected ? null : AppTheme.dividerColor.withOpacity(0.4),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? AppTheme.primaryColor : AppTheme.textColor.withOpacity(0.6),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.primaryColor : AppTheme.textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

