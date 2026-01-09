import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../bloc/user_bloc.dart';
import 'widgets/add_visitor_dialog.dart';
import 'visitor_details_page.dart';

class VisitorsPage extends StatelessWidget {
  final UserModel user;

  const VisitorsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVisitorDialog(context),
            tooltip: 'Add Visitor',
          ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UserLoaded) {
            // Filter visitors by user's block and room if available
            final visitors = state.visitors.where((v) {
              if (user.block != null && user.roomNumber != null) {
                return v.block == user.block && v.homeNumber == user.roomNumber;
              }
              return true; // Show all if user doesn't have block/room assigned
            }).toList();

            if (visitors.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: AppTheme.textColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No visitors added yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddVisitorDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Visitor'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visitors.length,
              itemBuilder: (context, index) {
                final visitor = visitors[index];
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
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitorDetailsPage(visitor: visitor),
                        ),
                      );
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.transparent,
                        child: visitor.image != null
                            ? ClipOval(
                                child: Image.network(
                                  visitor.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person, color: Colors.white, size: 24);
                                  },
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                    ),
                    title: Text(
                      visitor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mobile: ${visitor.mobileNumber}'),
                        Text('Type: ${visitor.type.name.toUpperCase()}'),
                        Text('Visit Time: ${_formatDateTime(visitor.visitTime)}'),
                      ],
                    ),
                      trailing: visitor.isRegistered
                          ? Icon(Icons.check_circle, color: AppTheme.secondaryColor)
                          : Icon(Icons.pending, color: AppTheme.accentColor),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Error loading visitors'));
        },
      ),
    );
  }

  void _showAddVisitorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddVisitorDialog(userId: user.id),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
