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

enum _VisitorListSection { today, upcoming, viewAll }

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
      case _VisitorListSection.today:
        return state.visitors.where((v) => _isSameDay(v.visitTime, now)).toList();
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
      body: BlocBuilder<SecurityBloc, SecurityState>(
        builder: (context, state) {
          if (state is SecurityLoaded) {
            final filtered = _filteredVisitors(state);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _GridCard(
                        icon: Icons.person_add,
                        label: 'Add Visitor',
                        onTap: () => _showAddVisitorDialog(context, state.blocks),
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
                        onTap: () => setState(() => _activeSection = _VisitorListSection.upcoming),
                        isSelected: _activeSection == _VisitorListSection.upcoming,
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
                        onTap: () => _showVerifyVisitorDialog(context, state.visitors),
                      ),
                    ],
                  ),
                ),
                if (filtered.isNotEmpty)
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
                                '${filtered.length} visitor${filtered.length == 1 ? "" : "s"}',
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
                  child: filtered.isEmpty
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
                                _activeSection == _VisitorListSection.today
                                    ? 'No visitors today'
                                    : _activeSection == _VisitorListSection.upcoming
                                        ? 'No upcoming visitors'
                                        : 'No visitors registered',
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
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final visitor = filtered[index];
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
                                        visitor.type.displayName.toUpperCase(),
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

  void _showVerifyVisitorDialog(BuildContext context, List<VisitorModel> visitors) {
    showDialog(
      context: context,
      builder: (context) => _VerifyVisitorDialog(visitors: visitors),
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

class _VerifyVisitorDialog extends StatefulWidget {
  final List<VisitorModel> visitors;

  const _VerifyVisitorDialog({required this.visitors});

  @override
  State<_VerifyVisitorDialog> createState() => _VerifyVisitorDialogState();
}

class _VerifyVisitorDialogState extends State<_VerifyVisitorDialog> {
  final _visitorIdController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _visitorIdController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _verify() {
    final id = _visitorIdController.text.trim();
    final otp = _otpController.text.trim();
    if (id.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter visitor ID and OTP')),
      );
      return;
    }
    VisitorModel? visitor;
    for (final v in widget.visitors) {
      if (v.id == id) { visitor = v; break; }
    }
    if (visitor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visitor not found')),
      );
      return;
    }
    if (visitor.otp != otp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verified: ${visitor.name}')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Visitor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _visitorIdController,
            decoration: const InputDecoration(
              labelText: 'Visitor ID',
              hintText: 'Enter visitor ID or scan QR',
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'OTP',
              hintText: '6-digit OTP',
              prefixIcon: Icon(Icons.lock),
            ),
            maxLength: 6,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _verify,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

class _AddVisitorDialog extends StatefulWidget {
  final List<BlockModel> blocks;

  const _AddVisitorDialog({required this.blocks});

  @override
  State<_AddVisitorDialog> createState() => _AddVisitorDialogState();
}

class _RoomOption {
  final FloorModel floor;
  final RoomModel room;
  _RoomOption(this.floor, this.room);
  String get label => 'Floor ${floor.number} – ${room.number}';
}

class _AddVisitorDialogState extends State<_AddVisitorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _purposeController = TextEditingController();
  final _vehicleController = TextEditingController();

  BlockModel? _selectedBlock;
  _RoomOption? _selectedRoomOption;
  VisitorType? _selectedType;
  late DateTime _entryTime;
  File? _visitorImage;
  final ImagePicker _picker = ImagePicker();

  List<_RoomOption> get _blockRooms {
    if (_selectedBlock == null) return [];
    final list = <_RoomOption>[];
    for (final f in _selectedBlock!.floors) {
      for (final r in f.rooms) {
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
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _purposeController.dispose();
    _vehicleController.dispose();
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
        _selectedRoomOption != null &&
        _selectedType != null) {
      context.read<SecurityBloc>().add(
            AddVisitorEvent(
              name: _nameController.text.trim(),
              mobileNumber: _mobileController.text.trim(),
              type: _selectedType!,
              block: _selectedBlock!.name,
              homeNumber: _selectedRoomOption!.room.number,
              image: _visitorImage?.path,
              purposeOfVisit: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
              vehicleNumber: _vehicleController.text.trim().isEmpty ? null : _vehicleController.text.trim(),
            ),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entryTimeStr =
        '${_entryTime.day}/${_entryTime.month}/${_entryTime.year} ${_entryTime.hour}:${_entryTime.minute.toString().padLeft(2, '0')}';
    return AlertDialog(
      title: const Text('Add Visitor'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    _selectedRoomOption = null;
                  });
                },
              ),
              if (_selectedBlock != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<_RoomOption>(
                  value: _selectedRoomOption,
                  decoration: const InputDecoration(
                    labelText: 'Select Room / Flat Number',
                    prefixIcon: Icon(Icons.door_front_door),
                  ),
                  items: _blockRooms.map((opt) {
                    return DropdownMenuItem(
                      value: opt,
                      child: Text(opt.label),
                    );
                  }).toList(),
                  onChanged: (opt) {
                    setState(() => _selectedRoomOption = opt);
                  },
                ),
              ],
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
              const Text('Visitor Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemCount: visitorTypeDisplayNames.length,
                itemBuilder: (context, index) {
                  final type = VisitorType.values[index];
                  return ChoiceChip(
                    label: Text(
                      visitorTypeDisplayNames[index],
                      style: const TextStyle(fontSize: 11),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose of Visit (optional)',
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number (for cab/delivery)',
                  hintText: 'Optional',
                  prefixIcon: Icon(Icons.directions_car),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 20, color: AppTheme.textColor.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Entry Time (auto): $entryTimeStr',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Photo / ID (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
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

