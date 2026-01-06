import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/models/user_model.dart';
import '../../bloc/admin_bloc.dart';

class UsersTab extends StatelessWidget {
  final AdminLoaded state;

  const UsersTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, blocState) {
        final currentState = blocState is AdminLoaded ? blocState : state;
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to user registration page with fromAdmin flag
                        Navigator.pushNamed(
                          context,
                          AppRoutes.userRegistration,
                          arguments: {'fromAdmin': true},
                        ).then((_) {
                          // When returning from registration, reload users
                          context.read<AdminBloc>().add(LoadAllUsersEvent());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      context.read<AdminBloc>().add(LoadAllUsersEvent());
                    },
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
            if (currentState.regularUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Total Users: ${currentState.regularUsers.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: currentState.regularUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppTheme.textColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users added yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textColor.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to user registration page with fromAdmin flag
                              Navigator.pushNamed(
                                context,
                                AppRoutes.userRegistration,
                                arguments: {'fromAdmin': true},
                              ).then((_) {
                                // When returning from registration, reload users
                                context.read<AdminBloc>().add(LoadAllUsersEvent());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add First User'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        context.read<AdminBloc>().add(LoadAllUsersEvent());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: currentState.regularUsers.length,
                        itemBuilder: (context, index) {
                          final user = currentState.regularUsers[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getStatusColor(user.status).withOpacity(0.1),
                                  _getStatusColor(user.status).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(user.status).withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              isThreeLine: true,
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: _getStatusColor(user.status),
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email,
                                          size: 12,
                                          color: AppTheme.textColor.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            user.email,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textColor.withOpacity(0.7),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 12,
                                          color: AppTheme.textColor.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.mobileNumber,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textColor.withOpacity(0.7),
                                          ),
                                        ),
                                        if (user.block != null) ...[
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.apartment,
                                            size: 12,
                                            color: AppTheme.textColor.withOpacity(0.6),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'B${user.block} F${user.floor} R${user.roomNumber}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textColor.withOpacity(0.6),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(user.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getShortStatus(user.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Switch(
                                    value: user.isActive,
                                    onChanged: (value) {
                                      context.read<AdminBloc>().add(
                                            ToggleUserActiveEvent(user.id),
                                          );
                                    },
                                    activeColor: AppTheme.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          );
                  },
                ),
            ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(AccountStatus status) {
    switch (status) {
      case AccountStatus.approved:
        return AppTheme.secondaryColor;
      case AccountStatus.pending:
        return AppTheme.accentColor;
      case AccountStatus.rejected:
        return AppTheme.errorColor;
    }
  }

  String _getShortStatus(AccountStatus status) {
    switch (status) {
      case AccountStatus.approved:
        return 'APP';
      case AccountStatus.pending:
        return 'PEN';
      case AccountStatus.rejected:
        return 'REJ';
    }
  }
}
