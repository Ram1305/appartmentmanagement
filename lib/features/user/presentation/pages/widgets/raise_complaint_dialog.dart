import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/models/complaint_model.dart';
import '../../bloc/user_bloc.dart';

class RaiseComplaintDialog extends StatefulWidget {
  final String userId;

  const RaiseComplaintDialog({super.key, required this.userId});

  @override
  State<RaiseComplaintDialog> createState() => _RaiseComplaintDialogState();
}

class _RaiseComplaintDialogState extends State<RaiseComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ComplaintType? _selectedType;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && _selectedType != null) {
      context.read<UserBloc>().add(
            RaiseComplaintEvent(
              userId: widget.userId,
              type: _selectedType!,
              description: _descriptionController.text.trim(),
            ),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Raise Complaint'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Complaint Type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ComplaintType.values.map((type) {
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your complaint...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
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
          onPressed: _handleSubmit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

