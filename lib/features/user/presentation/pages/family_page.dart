import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/family_member_model.dart';
import '../../../../core/services/api_service.dart';
import 'widgets/add_family_member_sheet.dart';

class FamilyPage extends StatefulWidget {
  final UserModel user;

  const FamilyPage({super.key, required this.user});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final ApiService _apiService = ApiService();
  List<FamilyMemberModel> _familyMembers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() => _loading = true);
    try {
      final response = await _apiService.getFamilyMembers();
      if (mounted && response['success'] == true) {
        final list = response['familyMembers'] as List? ?? [];
        setState(() {
          _familyMembers = list
              .map((e) => FamilyMemberModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddFamilyMemberSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddFamilyMemberSheet(),
    );
    if (added == true && mounted) {
      _loadFamilyMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Family'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFamilyMemberSheet,
            tooltip: 'Add family member',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _familyMembers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.family_restroom_rounded,
                        size: 80,
                        color: AppTheme.textColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No family members added yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddFamilyMemberSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add your first family member'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _familyMembers.length,
                  itemBuilder: (context, index) {
                    final member = _familyMembers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: member.profileImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: CachedNetworkImage(
                                    imageUrl: member.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.person,
                                      color: AppTheme.primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.displayRelation,
                              style: TextStyle(
                                color: AppTheme.textColor.withOpacity(0.7),
                              ),
                            ),
                            if (member.formattedDateOfBirth != null)
                              Text(
                                'DOB: ${member.formattedDateOfBirth}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textColor.withOpacity(0.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
