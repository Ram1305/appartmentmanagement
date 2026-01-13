import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/models/block_model.dart';
import '../../../../../core/models/user_model.dart';
import '../../bloc/admin_bloc.dart';

class BlocksTab extends StatelessWidget {
  final AdminLoaded state;

  const BlocksTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final totalRooms = state.blocks.fold<int>(
      0,
      (sum, block) => sum + block.floors.fold<int>(0, (s, floor) => s + floor.rooms.length),
    );
    final totalFloors = state.blocks.fold<int>(0, (sum, block) => sum + block.floors.length);

    return Column(
      children: [
        // Header with stats and create button
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.secondaryColor.withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.apartment,
                      label: 'Total Blocks',
                      value: '${state.blocks.length}',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.layers,
                      label: 'Total Floors',
                      value: '$totalFloors',
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.home,
                      label: 'Total Rooms',
                      value: '$totalRooms',
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCreateBlockDialog(context),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text(
                    'Create New Block',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
            style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
            ),
                    elevation: 4,
          ),
        ),
              ),
            ],
          ),
        ),
        // Blocks List
        Expanded(
          child: state.blocks.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 54), // Added extra bottom padding (38 + 16 = 54)
                  itemCount: state.blocks.length,
                  itemBuilder: (context, index) {
                    final block = state.blocks[index];
                    return _buildBlockCard(context, block, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
                    return Container(
      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.apartment_outlined,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Blocks Created Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first block to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateBlockDialog(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create Block'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockCard(BuildContext context, BlockModel block, int index) {
    final totalRooms = block.floors.fold<int>(0, (sum, floor) => sum + floor.rooms.length);
    // Calculate occupied rooms by checking if any user is assigned to the room
    final activeRooms = block.floors.fold<int>(
      0,
      (sum, floor) {
        final occupiedInFloor = floor.rooms.where((room) {
          return state.allUsers.any((user) =>
              user.block == block.name &&
              user.floor == floor.number &&
              user.roomNumber == room.number &&
              user.status == AccountStatus.approved);
        }).length;
        return sum + occupiedInFloor;
      },
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
          color: block.isActive
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
            color: block.isActive
                ? AppTheme.primaryColor.withOpacity(0.15)
                : Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
                          ),
                        ],
                      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.blockDetails,
              arguments: block,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Block Icon Badge
                    Container(
                      width: 40,
                      height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                          colors: block.isActive
                              ? [
                                AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                ]
                              : [
                                  Colors.grey[400]!,
                                  Colors.grey[500]!,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                            color: (block.isActive
                                    ? AppTheme.primaryColor
                                    : Colors.grey)
                                .withOpacity(0.4),
                            blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              block.name,
                              style: const TextStyle(
                                color: Colors.white,
                            fontSize: 24,
                                fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(width: 16),
                    // Title and Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child:                           Text(
                          'Block ${block.name}',
                          style: const TextStyle(
                                    fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: block.isActive
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: block.isActive
                                            ? Colors.green
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      block.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: block.isActive
                                            ? Colors.green[700]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Stats Row
                          Row(
                            children: [
                              _buildInfoChip(
                                icon: Icons.layers,
                                label: '${block.floors.length}',
                                subLabel: 'Floors',
                                color: AppTheme.secondaryColor,
                              ),
                              const SizedBox(width: 12),
                              _buildInfoChip(
                                icon: Icons.home,
                                label: '$totalRooms',
                                subLabel: 'Rooms',
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(width: 12),
                              _buildInfoChip(
                                icon: Icons.person,
                                label: '$activeRooms',
                                subLabel: 'Occupied',
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                // Action Buttons Row
                Row(
                  children: [
                    // Toggle Switch
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.power_settings_new,
                            size: 18,
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status',
                          style: TextStyle(
                            fontSize: 14,
                              fontWeight: FontWeight.w500,
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                          const Spacer(),
                            Switch(
                              value: block.isActive,
                              onChanged: (value) {
                                context.read<AdminBloc>().add(
                                      ToggleBlockActiveEvent(block.id),
                                    );
                              },
                              activeColor: AppTheme.primaryColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                            ),
                            const SizedBox(width: 8),
                    // Action Buttons
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      color: Colors.blue,
                              onPressed: () => _showEditBlockDialog(context, block),
                              tooltip: 'Edit Block',
                            ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.add_circle_outline,
                      color: AppTheme.primaryColor,
                      onPressed: () => _showAddFloorDialog(context, block),
                      tooltip: 'Add Floor',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                              onPressed: () => _showDeleteBlockDialog(context, block),
                              tooltip: 'Delete Block',
                            ),
                  ],
                            ),
                          ],
                        ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 8,
                  color: color.withOpacity(0.7),
                ),
        ),
      ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  void _showCreateBlockDialog(BuildContext context) {
    final blockController = TextEditingController();
    final numberOfFloorsController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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
            // Title
            const Text(
              'Create New Block',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter block name and number of floors',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            // Block Name Field
            TextField(
              controller: blockController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Block Name',
                hintText: 'e.g., A, B, C',
                prefixIcon: const Icon(Icons.apartment, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLength: 1,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Number of Floors Field
            TextField(
              controller: numberOfFloorsController,
              decoration: InputDecoration(
                labelText: 'Number of Floors',
                hintText: 'e.g., 3, 5, 10',
                prefixIcon: const Icon(Icons.layers, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      blockController.dispose();
                      numberOfFloorsController.dispose();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (blockController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter block name'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      if (numberOfFloorsController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter number of floors'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      final numberOfFloors = int.tryParse(numberOfFloorsController.text.trim());
                      if (numberOfFloors == null || numberOfFloors <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid number of floors (greater than 0)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                        context.read<AdminBloc>().add(
                            CreateBlockEvent(
                              blockName: blockController.text.toUpperCase(),
                              numberOfFloors: numberOfFloors,
                            ),
                            );
                      
                      blockController.dispose();
                      numberOfFloorsController.dispose();
                        Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Create Block',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddFloorDialog(BuildContext context, BlockModel block) {
    final floorController = TextEditingController();
    final roomNumberController = TextEditingController();
    String selectedRoomType = '1BHK';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // Handle bar
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
              // Title
              Text(
                'Add Floor to Block ${block.name}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter floor and room details',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              // Floor Number Field
                    TextField(
                      controller: floorController,
                decoration: InputDecoration(
                        labelText: 'Floor Number',
                        hintText: 'e.g., 1, 2, 3',
                  prefixIcon: const Icon(Icons.layers, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
              // Room Number Field
              TextField(
                controller: roomNumberController,
                decoration: InputDecoration(
                  labelText: 'Room Number',
                  hintText: 'e.g., 101, 102, 201',
                  prefixIcon: const Icon(Icons.home, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              // Room Type Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Room Type',
                  prefixIcon: const Icon(Icons.apartment, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                value: selectedRoomType,
                                  items: ['1BHK', '2BHK', '3BHK', '4BHK', 'Studio']
                                      .map((type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                    selectedRoomType = value ?? '1BHK';
                                    });
                                  },
                                ),
              const SizedBox(height: 32),
              // Action Buttons
              Row(
                children: [
                              Expanded(
                    child: OutlinedButton(
                                onPressed: () {
                        floorController.dispose();
                        roomNumberController.dispose();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                                ),
                              ),
                            ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                  onPressed: () {
                        if (floorController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter floor number'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        if (roomNumberController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter room number'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        // Create room configuration with single room
                        final configs = [
                          {
                            'type': selectedRoomType,
                            'count': 1,
                          }
                        ];
                        
                        context.read<AdminBloc>().add(
                              AddFloorEvent(
                                blockId: block.id,
                                floorNumber: floorController.text.trim(),
                                roomConfigurations: configs,
                                roomNumber: roomNumberController.text.trim(),
                              ),
                            );
                        
                        floorController.dispose();
                        roomNumberController.dispose();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Add Floor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockDetails(BuildContext context, BlockModel block) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${block.name} Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: block.floors.length,
            itemBuilder: (context, index) {
              final floor = block.floors[index];
              return ExpansionTile(
                title: Text('Floor ${floor.number}'),
                children: floor.rooms.map((room) {
                  return ListTile(
                    title: Text('Room ${room.number}'),
                    subtitle: Text('Type: ${room.type}'),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditBlockDialog(BuildContext context, BlockModel block) {
    final blockController = TextEditingController(text: block.name);
    // Create controllers for each floor
    final Map<String, TextEditingController> floorControllers = {};
    for (var floor in block.floors) {
      floorControllers[floor.id] = TextEditingController(text: floor.number);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Track deleted floor IDs (persists across rebuilds)
        final Set<String> deletedFloorIds = {};
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter out deleted floors
            final currentFloors = block.floors.where((floor) => !deletedFloorIds.contains(floor.id)).toList();
            
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                'Edit Block',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update block name and floor numbers',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              // Block Name Field
              TextField(
                controller: blockController,
                decoration: InputDecoration(
                  labelText: 'Block Name',
                  hintText: 'e.g., A, B, C',
                  prefixIcon: const Icon(Icons.apartment, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLength: 1,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Floors Section
              if (currentFloors.isNotEmpty || block.floors.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.layers, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Floors (${currentFloors.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: currentFloors.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'No floors remaining',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: currentFloors.length,
                          itemBuilder: (context, index) {
                            final floor = currentFloors[index];
                            final floorController = floorControllers[floor.id]!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: floorController,
                                      decoration: InputDecoration(
                                        labelText: 'Floor Number',
                                        hintText: 'e.g., 1, 2, 3',
                                        prefixIcon: const Icon(Icons.layers, color: AppTheme.primaryColor, size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      keyboardType: TextInputType.text,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 22),
                                    color: Colors.red,
                                    onPressed: () {
                                      // Show confirmation dialog
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text(
                                            'Delete Floor?',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(
                                            'Floor ${floor.number} (${floor.rooms.length} rooms) will be permanently deleted.\nThis action cannot be undone.',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                // Delete the floor
                                                context.read<AdminBloc>().add(
                                                      DeleteFloorEvent(
                                                        blockId: block.id,
                                                        floorId: floor.id,
                                                      ),
                                                    );
                                                
                                                // Remove from local state
                                                setDialogState(() {
                                                  deletedFloorIds.add(floor.id);
                                                  floorControllers[floor.id]?.dispose();
                                                  floorControllers.remove(floor.id);
                                                });
                                                
                                                Navigator.pop(dialogContext);
                                                
                                                // Show success message
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Floor ${floor.number} deleted'),
                                                    backgroundColor: Colors.green,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    tooltip: 'Delete Floor',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No floors to edit. Add floors from the block details page.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Dispose controllers
                        for (var controller in floorControllers.values) {
                          controller.dispose();
                        }
                        blockController.dispose();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (blockController.text.isNotEmpty) {
                          // Update block name
                          context.read<AdminBloc>().add(
                                EditBlockEvent(
                                  blockId: block.id,
                                  name: blockController.text.toUpperCase(),
                                ),
                              );
                          
                          // Update floor numbers if changed (only for floors that still exist)
                          for (var floor in currentFloors) {
                            if (floorControllers.containsKey(floor.id)) {
                              final floorController = floorControllers[floor.id]!;
                              if (floorController.text.trim().isNotEmpty && 
                                  floorController.text.trim() != floor.number) {
                                context.read<AdminBloc>().add(
                                      EditFloorEvent(
                                        blockId: block.id,
                                        floorId: floor.id,
                                        floorNumber: floorController.text.trim(),
                                      ),
                                    );
                              }
                            }
                          }
                          
                          // Dispose controllers
                          for (var controller in floorControllers.values) {
                            controller.dispose();
                          }
                          blockController.dispose();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Update Block',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteBlockDialog(BuildContext context, BlockModel block) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Delete Block?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Block ${block.name} will be permanently deleted.\nThis action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AdminBloc>().add(DeleteBlockEvent(block.id));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
