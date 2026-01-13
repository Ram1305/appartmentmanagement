import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/app_theme.dart';
import '../../../../../../core/models/complaint_model.dart';
import '../../bloc/user_bloc.dart';
import 'raise_complaint_dialog.dart';

class ComplaintsTab extends StatelessWidget {
  final String userId;

  const ComplaintsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoaded) {
            final complaints = state.complaints
                .where((c) => c.userId == userId)
                .toList();
            
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textColor.withOpacity(0.6),
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.grid_view_rounded, size: 20),
                          text: 'Categories',
                        ),
                        Tab(
                          icon: Icon(Icons.list_rounded, size: 20),
                          text: 'My Complaints',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Categories Grid View
                        _buildCategoryGrid(),
                        // Complaints List View
                        complaints.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.report_problem_outlined,
                                          size: 64,
                                          color: AppTheme.primaryColor.withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'No Complaints Yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap the button below to raise\na new complaint',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textColor.withOpacity(0.6),
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      ElevatedButton.icon(
                                        onPressed: () => _showRaiseComplaintDialog(context, null),
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        label: const Text(
                                          'Raise Complaint',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 4,
                                          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(complaint.status).withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                        spreadRadius: 0,
                      ),
                    ],
                    border: Border.all(
                      color: _getStatusColor(complaint.status).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            // Status Icon
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _getStatusColor(complaint.status),
                                    _getStatusColor(complaint.status).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColor(complaint.status).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getStatusIcon(complaint.status),
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Complaint Type
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(complaint.status)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      complaint.type.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(complaint.status),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(complaint.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      complaint.status.name.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          complaint.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textColor,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Room Details
                        if (complaint.block != null ||
                            complaint.floor != null ||
                            complaint.roomNumber != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.home_rounded,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _buildRoomDetails(complaint),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Footer with Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppTheme.textColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(complaint.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textColor.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: AppTheme.textColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              complaint.userName,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textColor.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
        return Icons.pending_rounded;
      case ComplaintStatus.inProgress:
        return Icons.work_rounded;
      case ComplaintStatus.resolved:
        return Icons.check_circle_rounded;
      case ComplaintStatus.rejected:
        return Icons.cancel_rounded;
    }
  }

  String _buildRoomDetails(ComplaintModel complaint) {
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
    return parts.isEmpty ? 'Room details not available' : parts.join(' • ');
  }

  void _showRaiseComplaintDialog(BuildContext context, ComplaintType? type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RaiseComplaintDialog(userId: userId, initialType: type),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {
        'type': ComplaintType.plumbing,
        'icon': Icons.plumbing_rounded,
        'label': 'Plumbing',
        'color': const Color(0xFF2196F3),
        'gradient': [const Color(0xFF2196F3), const Color(0xFF1976D2)],
      },
      {
        'type': ComplaintType.electrical,
        'icon': Icons.electrical_services_rounded,
        'label': 'Electrical',
        'color': const Color(0xFFFF9800),
        'gradient': [const Color(0xFFFF9800), const Color(0xFFF57C00)],
      },
      {
        'type': ComplaintType.cleaning,
        'icon': Icons.cleaning_services_rounded,
        'label': 'Cleaning',
        'color': const Color(0xFF4CAF50),
        'gradient': [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
      },
      {
        'type': ComplaintType.maintenance,
        'icon': Icons.build_rounded,
        'label': 'Maintenance',
        'color': const Color(0xFF9C27B0),
        'gradient': [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
      },
      {
        'type': ComplaintType.security,
        'icon': Icons.security_rounded,
        'label': 'Security',
        'color': const Color(0xFFF44336),
        'gradient': [const Color(0xFFF44336), const Color(0xFFD32F2F)],
      },
      {
        'type': ComplaintType.other,
        'icon': Icons.more_horiz_rounded,
        'label': 'Others',
        'color': const Color(0xFF757575),
        'gradient': [const Color(0xFF757575), const Color(0xFF616161)],
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final gradientColors = category['gradient'] as List<Color>;
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showRaiseComplaintDialog(context, category['type'] as ComplaintType),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColors[0].withOpacity(0.1),
                    gradientColors[1].withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (category['color'] as Color).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (category['color'] as Color).withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container with Gradient Background
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: (category['color'] as Color).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category Label
                  Text(
                    category['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  // Subtle indicator
                  Container(
                    width: 30,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

