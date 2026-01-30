import 'package:flutter/material.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/models/family_member_model.dart';
import '../../../../../core/services/api_service.dart';

/// Bottom sheet for residents to report when a child is exiting the premises.
/// Notifies security for better communication and safety.
class ReportKidExitSheet extends StatefulWidget {
  const ReportKidExitSheet({super.key});

  @override
  State<ReportKidExitSheet> createState() => _ReportKidExitSheetState();
}

class _ReportKidExitSheetState extends State<ReportKidExitSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  List<FamilyMemberModel> _familyMembers = [];
  List<FamilyMemberModel> _children = [];
  bool _loading = true;
  bool _submitting = false;
  FamilyMemberModel? _selectedChild;
  bool _useCustomName = false;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() => _loading = true);
    try {
      final response = await _apiService.getFamilyMembers();
      if (mounted && response['success'] == true && response['familyMembers'] != null) {
        final list = (response['familyMembers'] as List)
            .map((e) => FamilyMemberModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final children = list.where((m) => m.relationType == 'child').toList();
        setState(() {
          _familyMembers = list;
          _children = children;
          _loading = false;
          if (children.isNotEmpty && _selectedChild == null) {
            _selectedChild = children.first;
            _nameController.text = children.first.name;
          }
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the child\'s name'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await _apiService.reportKidExit(
        kidName: name,
        familyMemberId: _selectedChild?.id,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      if (response['success'] == true) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    response['message'] as String? ?? 'Security notified. Kid exit reported.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error']?.toString() ?? 'Failed to report'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.child_care_rounded,
                      size: 28,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Kid Exit',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Notify security when a child is leaving the premises',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                )
              else ...[
                const Text(
                  'Who is exiting?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (_children.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<FamilyMemberModel?>(
                          value: _useCustomName ? null : _selectedChild,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          hint: const Text('Select child'),
                          items: [
                            ..._children.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                )),
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Other (type name)'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedChild = v;
                              _useCustomName = v == null;
                              if (v != null) {
                                _nameController.text = v.name;
                              } else {
                                _nameController.clear();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _children.isNotEmpty ? 'Name (or edit above)' : 'Child\'s name',
                    hintText: 'Enter name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g. Going to school, pickup by 4 PM',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.note_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Notify Security', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
