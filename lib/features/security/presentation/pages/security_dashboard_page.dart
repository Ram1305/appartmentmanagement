import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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

class _SecurityDashboardPageState extends State<SecurityDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<SecurityBloc>().add(LoadSecurityDataEvent());
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
      body: BlocBuilder<SecurityBloc, SecurityState>(
        builder: (context, state) {
          if (state is SecurityLoaded) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddVisitorDialog(context, state.blocks),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Visitor'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
                if (state.visitors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
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
                                'Total Visitors: ${state.visitors.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: state.visitors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_disabled,
                                size: 64,
                                color: AppTheme.textColor.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No visitors registered',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.visitors.length,
                          itemBuilder: (context, index) {
                            final visitor = state.visitors[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryColor.withOpacity(0.1),
                                    AppTheme.secondaryColor.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
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
                                contentPadding: const EdgeInsets.all(20),
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.primaryColor.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: visitor.image != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.network(
                                            visitor.image!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.person, color: Colors.white, size: 32),
                                ),
                                title: Text(
                                  visitor.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        visitor.type.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.phone, size: 14, color: AppTheme.textColor.withOpacity(0.6)),
                                        const SizedBox(width: 4),
                                        Text(
                                          visitor.mobileNumber,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.apartment, size: 14, color: AppTheme.textColor.withOpacity(0.6)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Block ${visitor.block} • Room ${visitor.homeNumber}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (visitor.otp != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppTheme.accentColor.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.lock, size: 16, color: AppTheme.accentColor),
                                            const SizedBox(width: 8),
                                            Text(
                                              'OTP: ${visitor.otp}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.accentColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: AppTheme.textColor.withOpacity(0.6)),
                                    const SizedBox(height: 4),
                                    Text(
                                      visitor.visitTime.toString().split(' ')[0],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textColor.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      visitor.visitTime.toString().split(' ')[1].substring(0, 5),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textColor.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
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

  void _showAddVisitorDialog(BuildContext context, List<BlockModel> blocks) {
    showDialog(
      context: context,
      builder: (context) => _AddVisitorDialog(blocks: blocks),
    );
  }
}

class _AddVisitorDialog extends StatefulWidget {
  final List<BlockModel> blocks;

  const _AddVisitorDialog({required this.blocks});

  @override
  State<_AddVisitorDialog> createState() => _AddVisitorDialogState();
}

class _AddVisitorDialogState extends State<_AddVisitorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  
  BlockModel? _selectedBlock;
  FloorModel? _selectedFloor;
  RoomModel? _selectedRoom;
  VisitorType? _selectedType;
  File? _visitorImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
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

  void _handleAdd() {
    if (_formKey.currentState!.validate() &&
        _selectedBlock != null &&
        _selectedRoom != null &&
        _selectedType != null) {
      // TODO: Check if user registered this visitor
      // For now, directly add visitor. In production, check visitor registration status
      context.read<SecurityBloc>().add(
            AddVisitorEvent(
              name: _nameController.text.trim(),
              mobileNumber: _mobileController.text.trim(),
              type: _selectedType!,
              block: _selectedBlock!.name,
              homeNumber: _selectedRoom!.number,
              image: _visitorImage?.path,
            ),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Visitor'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                  ),
                  child: _visitorImage != null
                      ? ClipOval(
                          child: Image.file(
                            _visitorImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.add_a_photo, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Visitor Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter visitor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BlockModel>(
                value: _selectedBlock,
                decoration: const InputDecoration(
                  labelText: 'Select Block',
                  prefixIcon: Icon(Icons.apartment),
                ),
                items: widget.blocks.map((block) {
                  return DropdownMenuItem(
                    value: block,
                    child: Text('Block ${block.name}'),
                  );
                }).toList(),
                onChanged: (block) {
                  setState(() {
                    _selectedBlock = block;
                    _selectedFloor = null;
                    _selectedRoom = null;
                  });
                },
              ),
              if (_selectedBlock != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<FloorModel>(
                  value: _selectedFloor,
                  decoration: const InputDecoration(
                    labelText: 'Select Floor',
                    prefixIcon: Icon(Icons.stairs),
                  ),
                  items: _selectedBlock!.floors.map((floor) {
                    return DropdownMenuItem(
                      value: floor,
                      child: Text('Floor ${floor.number}'),
                    );
                  }).toList(),
                  onChanged: (floor) {
                    setState(() {
                      _selectedFloor = floor;
                      _selectedRoom = null;
                    });
                  },
                ),
              ],
              if (_selectedFloor != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<RoomModel>(
                  value: _selectedRoom,
                  decoration: const InputDecoration(
                    labelText: 'Select Room',
                    prefixIcon: Icon(Icons.door_front_door),
                  ),
                  items: _selectedFloor!.rooms.map((room) {
                    return DropdownMenuItem(
                      value: room,
                      child: Text('Room ${room.number}'),
                    );
                  }).toList(),
                  onChanged: (room) {
                    setState(() {
                      _selectedRoom = room;
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              const Text('Visitor Type'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: VisitorType.values.length,
                itemBuilder: (context, index) {
                  final type = VisitorType.values[index];
                  return ChoiceChip(
                    label: Text(
                      type.name.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleAdd,
          child: const Text('Add Visitor'),
        ),
      ],
    );
  }
}

