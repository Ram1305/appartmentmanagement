import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../../core/app_theme.dart';
import '../../../../../../core/models/visitor_model.dart';
import '../../bloc/user_bloc.dart';
import '../visitor_details_page.dart';

class AddVisitorDialog extends StatefulWidget {
  final String userId;

  const AddVisitorDialog({super.key, required this.userId});

  @override
  State<AddVisitorDialog> createState() => _AddVisitorDialogState();
}

class _AddVisitorDialogState extends State<AddVisitorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _reasonController = TextEditingController();

  File? _visitorImage;
  VisitorCategory? _selectedCategory;
  RelativeType? _selectedRelativeType;
  VisitorType? _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _reasonController.dispose();
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _handleAdd() async {
    if (_formKey.currentState!.validate() &&
        _selectedCategory != null &&
        _selectedDate != null &&
        _selectedTime != null) {
      if (_selectedCategory == VisitorCategory.relative && _selectedRelativeType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select relative type')),
        );
        return;
      }
      if (_selectedCategory == VisitorCategory.outsider && _selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select visitor type')),
        );
        return;
      }

      final visitDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Add visitor and wait for state update
      context.read<UserBloc>().add(
            AddVisitorEvent(
              userId: widget.userId,
              name: _nameController.text.trim(),
              mobileNumber: _mobileController.text.trim(),
              category: _selectedCategory!,
              relativeType: _selectedRelativeType,
              type: _selectedType,
              reasonForVisit: _reasonController.text.trim(),
              visitDateTime: visitDateTime,
              image: _visitorImage,
            ),
          );
      
      // Close dialog and navigate to visitor details
      Navigator.pop(context);
      
      // Wait a bit for state to update, then navigate
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Get the latest visitor from state
      final state = context.read<UserBloc>().state;
      if (state is UserLoaded && state.visitors.isNotEmpty) {
        final latestVisitor = state.visitors.last;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitorDetailsPage(visitor: latestVisitor),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Add Visitor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker (Optional)
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.dividerColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            child: _visitorImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _visitorImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        color: AppTheme.primaryColor,
                                        size: 30,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textColor.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Category Dropdown (Relative/Outsider)
                      DropdownButtonFormField<VisitorCategory>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        dropdownColor: Colors.white,
                        items: VisitorCategory.values.map((category) {
                          return DropdownMenuItem<VisitorCategory>(
                            value: category,
                            child: Text(
                              category.name.toUpperCase(),
                              style: const TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                            _selectedRelativeType = null;
                            _selectedType = null;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Relative Type Dropdown (only if relative selected)
                      if (_selectedCategory == VisitorCategory.relative) ...[
                        DropdownButtonFormField<RelativeType>(
                          value: _selectedRelativeType,
                          decoration: const InputDecoration(
                            labelText: 'Relative Type *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.family_restroom),
                          ),
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                          dropdownColor: Colors.white,
                          items: RelativeType.values.map((type) {
                            return DropdownMenuItem<RelativeType>(
                              value: type,
                              child: Text(
                                type.name.toUpperCase(),
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRelativeType = value;
                            });
                          },
                          validator: (value) {
                            if (_selectedCategory == VisitorCategory.relative && value == null) {
                              return 'Please select relative type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Visitor Type Dropdown (only if outsider selected)
                      if (_selectedCategory == VisitorCategory.outsider) ...[
                        DropdownButtonFormField<VisitorType>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Visitor Type *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                          dropdownColor: Colors.white,
                          items: VisitorType.values.map((type) {
                            return DropdownMenuItem<VisitorType>(
                              value: type,
                              child: Text(
                                type.displayName,
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value;
                            });
                          },
                          validator: (value) {
                            if (_selectedCategory == VisitorCategory.outsider && value == null) {
                              return 'Please select visitor type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Mobile Number
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number *',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter mobile number';
                          }
                          if (value.length != 10) {
                            return 'Please enter valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Reason for Visit
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Visit *',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter reason for visit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Visit Date
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Visit Date *',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Select Date',
                            style: TextStyle(
                              color: _selectedDate != null
                                  ? AppTheme.textColor
                                  : AppTheme.textColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Visit Time
                      InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Visit Time *',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _selectedTime != null
                                ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                : 'Select Time',
                            style: TextStyle(
                              color: _selectedTime != null
                                  ? AppTheme.textColor
                                  : AppTheme.textColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add Visitor'),
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
