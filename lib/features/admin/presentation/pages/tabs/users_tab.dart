import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/models/user_model.dart';
import '../../../../../core/models/block_model.dart';
import '../../../../../core/services/api_service.dart';
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
              padding: const EdgeInsets.all(12),
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
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add User', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: () {
                      context.read<AdminBloc>().add(LoadAllUsersEvent());
                    },
                    tooltip: 'Refresh',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            if (currentState.regularUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Total Users: ${currentState.regularUsers.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: currentState.regularUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: AppTheme.textColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No users added yet',
                            style: TextStyle(
                              fontSize: 14,
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
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add First User', style: TextStyle(fontSize: 12)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: currentState.regularUsers.length,
                        itemBuilder: (context, index) {
                          final user = currentState.regularUsers[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getStatusColor(user.status).withOpacity(0.1),
                                  _getStatusColor(user.status).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
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
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isThreeLine: true,
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: _getStatusColor(user.status),
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email,
                                          size: 10,
                                          color: AppTheme.textColor.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            user.email,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textColor.withOpacity(0.7),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 10,
                                          color: AppTheme.textColor.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          user.mobileNumber,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textColor.withOpacity(0.7),
                                          ),
                                        ),
                                        if (user.block != null) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.apartment,
                                            size: 10,
                                            color: AppTheme.textColor.withOpacity(0.6),
                                          ),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              'B${user.block} F${user.floor} R${user.roomNumber}',
                                              style: TextStyle(
                                                fontSize: 10,
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
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(user.status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getShortStatus(user.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32),
                                    itemBuilder: (context) {
                                      final items = <PopupMenuItem<String>>[];
                                      if (user.status == AccountStatus.pending ||
                                          user.status == AccountStatus.rejected) {
                                        items.add(
                                          const PopupMenuItem<String>(
                                            value: 'approve',
                                            child: Row(
                                              children: [
                                                Icon(Icons.check_circle, size: 16, color: AppTheme.secondaryColor),
                                                SizedBox(width: 8),
                                                Text('Approve & assign room', style: TextStyle(fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      if (user.status != AccountStatus.rejected) {
                                        items.add(
                                          const PopupMenuItem<String>(
                                            value: 'reject',
                                            child: Row(
                                              children: [
                                                Icon(Icons.cancel, size: 16, color: AppTheme.errorColor),
                                                SizedBox(width: 8),
                                                Text('Reject', style: TextStyle(fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      return items;
                                    },
                                    onSelected: (value) {
                                      if (value == 'approve') {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (ctx) => _ApprovalBottomSheet(tenant: user),
                                        );
                                      } else if (value == 'reject') {
                                        context.read<AdminBloc>().add(
                                          UpdateUserStatusEvent(
                                            userId: user.id,
                                            status: AccountStatus.rejected,
                                          ),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('User rejected'),
                                            backgroundColor: AppTheme.errorColor,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Switch(
                                    value: user.isActive,
                                    onChanged: (value) {
                                      context.read<AdminBloc>().add(
                                            ToggleUserActiveEvent(user.id),
                                          );
                                    },
                                    activeColor: AppTheme.primaryColor,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

/// Bottom sheet for admin to approve a user and assign block/floor/room.
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
            const Text(
              'Approve User',
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
                  if (value == null) return 'Please select a block';
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                  if (value == null) return 'Please select a floor';
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                        setState(() => _selectedRoom = value);
                      },
                validator: (value) {
                  if (value == null) return 'Please select a room';
                  return null;
                },
              ),
              const SizedBox(height: 24),
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
                          context.read<AdminBloc>().add(
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
                              content: Text('User approved and room assigned successfully.'),
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
