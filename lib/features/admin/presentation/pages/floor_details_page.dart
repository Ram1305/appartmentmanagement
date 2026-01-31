import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/block_model.dart';
import '../bloc/admin_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FloorDetailsPage extends StatefulWidget {
  final FloorModel floor;
  final BlockModel block;

  const FloorDetailsPage({
    super.key,
    required this.floor,
    required this.block,
  });

  @override
  State<FloorDetailsPage> createState() => _FloorDetailsPageState();
}

class _FloorDetailsPageState extends State<FloorDetailsPage> {
  FloorModel? _currentFloor;
  BlockModel? _currentBlock;
  int _previousRoomCount = 0; // Track previous room count for success message

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.floor;
    _currentBlock = widget.block;
    _previousRoomCount = widget.floor.rooms.length;
  }

  void _refreshFloor() {
    // Refresh block data from bloc
    final state = context.read<AdminBloc>().state;
    if (state is AdminLoaded) {
      final block = state.blocks.firstWhere(
        (b) => b.id == widget.block.id,
        orElse: () => widget.block,
      );
      final floor = block.floors.firstWhere(
        (f) => f.id == widget.floor.id,
        orElse: () => widget.floor,
      );
      setState(() {
        _currentBlock = block;
        _currentFloor = floor;
      });
    }
  }

  void _showAddRoomDialog(BuildContext context) {
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
              const Text(
                'Add New Room',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter room number and type',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              // Room Number Field
              TextField(
                controller: roomNumberController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Room Number',
                  hintText: 'e.g., 101, 102',
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
              // Room Type Field
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
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
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
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (roomNumberController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter room number'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        context.read<AdminBloc>().add(
                              AddRoomEvent(
                                blockId: _currentBlock!.id,
                                floorId: _currentFloor!.id,
                                roomNumber: roomNumberController.text.trim(),
                                roomType: selectedRoomType,
                              ),
                            );

                        roomNumberController.dispose();
                        Navigator.pop(context);
                        // Don't call _refreshFloor() here - BlocListener will handle the state update
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
                        'Add Room',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminLoaded) {
          final block = state.blocks.firstWhere(
            (b) => b.id == widget.block.id,
            orElse: () => widget.block,
          );
          final floor = block.floors.firstWhere(
            (f) => f.id == widget.floor.id,
            orElse: () => widget.floor,
          );
          if (mounted) {
            final previousCount = _currentFloor?.rooms.length ?? _previousRoomCount;
            setState(() {
              _currentBlock = block;
              _currentFloor = floor;
              _previousRoomCount = floor.rooms.length;
            });
            // Show success message if room count increased
            if (floor.rooms.length > previousCount) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Room added successfully!'),
                  backgroundColor: AppTheme.primaryColor,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else if (state is AdminError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Floor Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            final floor = _currentFloor ?? widget.floor;
            final block = _currentBlock ?? widget.block;

            return Column(
              children: [
                // Top Section - Floor Info
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.layers,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Floor ${floor.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Block ${block.name}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.home,
                            label: 'Total Rooms',
                            value: floor.rooms.length.toString(),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.person,
                            label: 'Occupied',
                            value: floor.rooms
                                .where((room) => room.isOccupied)
                                .length
                                .toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Rooms ListView
                Expanded(
                  child: floor.rooms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No rooms added yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add a room',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: floor.rooms.length,
                          itemBuilder: (context, index) {
                            final room = floor.rooms[index];
                            final isOccupied = room.isOccupied;

                            return _buildRoomListItem(
                              context,
                              room,
                              block,
                              floor,
                              isOccupied,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddRoomDialog(context),
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Room',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomListItem(
    BuildContext context,
    RoomModel room,
    BlockModel block,
    FloorModel floor,
    bool isOccupied,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOccupied
              ? Colors.orange.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Room Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isOccupied
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.door_front_door,
                color: isOccupied ? Colors.orange : Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Room Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room ${room.number}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      room.type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Occupied Toggle
            Column(
              children: [
                Text(
                  'Occupied',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Switch(
                  value: isOccupied,
                  onChanged: (value) {
                    context.read<AdminBloc>().add(
                          ToggleRoomOccupiedEvent(
                            blockId: block.id,
                            floorId: floor.id,
                            roomId: room.id,
                            isOccupied: value,
                          ),
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Room ${room.number} marked as occupied'
                                : 'Room ${room.number} marked as free',
                          ),
                          backgroundColor: AppTheme.primaryColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  activeColor: Colors.orange,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Edit Button
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: Colors.blue,
              onPressed: () => _showEditRoomDialog(context, room, block, floor),
              tooltip: 'Edit Room',
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () => _showDeleteRoomDialog(context, room, block, floor),
              tooltip: 'Delete Room',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
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

  void _showEditRoomDialog(BuildContext context, RoomModel room, BlockModel block, FloorModel floor) {
    final roomNumberController = TextEditingController(text: room.number);
    String selectedRoomType = room.type;

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
              const Text(
                'Edit Room',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update room number and type',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              // Room Number Field
              TextField(
                controller: roomNumberController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Room Number',
                  hintText: 'e.g., 101, 102',
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
              // Room Type Field
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
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
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
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (roomNumberController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter room number'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // TODO: Implement edit room API call
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit room functionality will be implemented soon'),
                            backgroundColor: Colors.orange,
                          ),
                        );

                        roomNumberController.dispose();
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
                        'Update Room',
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
      ),
    );
  }

  void _showDeleteRoomDialog(BuildContext context, RoomModel room, BlockModel block, FloorModel floor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Room',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete Room ${room.number}? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.textColor),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete room API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete room functionality will be implemented soon'),
                  backgroundColor: Colors.orange,
                ),
              );
              Navigator.pop(context);
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
  }
}

