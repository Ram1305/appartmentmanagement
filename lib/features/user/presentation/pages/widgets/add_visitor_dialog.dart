import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/models/visitor_model.dart';
import '../../bloc/user_bloc.dart';

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

  VisitorType? _selectedType;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (_formKey.currentState!.validate() && _selectedType != null) {
      context.read<UserBloc>().add(
            AddVisitorEvent(
              userId: widget.userId,
              name: _nameController.text.trim(),
              mobileNumber: _mobileController.text.trim(),
              type: _selectedType!,
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
              const Text('Visitor Type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: VisitorType.values.map((type) {
                  return ChoiceChip(
                    label: Text(type.name.toUpperCase()),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                    },
                  );
                }).toList(),
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
          child: const Text('Add'),
        ),
      ],
    );
  }
}

