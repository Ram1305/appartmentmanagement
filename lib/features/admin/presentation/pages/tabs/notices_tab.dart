import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/app_theme.dart';
import '../../../../../../core/models/event_model.dart';
import '../../../../../../core/services/api_service.dart';
import '../../bloc/admin_bloc.dart';
import '../widgets/add_event_dialog.dart';

class NoticesTab extends StatefulWidget {
  final AdminLoaded state;
  const NoticesTab({required this.state, super.key});
  
  @override
  State<NoticesTab> createState() => _NoticesTabState();
}

class _NoticesTabState extends State<NoticesTab> {
  final ApiService _apiService = ApiService();
  List<EventModel> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAllNotices(type: 'event');
      if (response['success'] == true && response['notices'] != null) {
        setState(() {
          _events = (response['notices'] as List)
              .map((e) => EventModel.fromJson(e))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addEvent(String title, String subtitle, String content, DateTime eventDate) async {
    try {
      final response = await _apiService.createNotice(
        title: title,
        subtitle: subtitle.isEmpty ? null : subtitle,
        content: content,
        type: 'event',
        targetAudience: 'all',
        eventDate: eventDate.toIso8601String(),
      );
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event added successfully')),
          );
          _loadEvents();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Failed to add event')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Events',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          AddEventDialog.show(context, _addEvent);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Event'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _events.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No events yet', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  child: const Icon(Icons.event, color: AppTheme.primaryColor),
                                ),
                                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (event.subtitle != null && event.subtitle!.isNotEmpty)
                                      Text(event.subtitle!, style: TextStyle(color: Colors.grey[700])),
                                    const SizedBox(height: 4),
                                    Text(event.content),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14),
                                        const SizedBox(width: 4),
                                        Text(event.eventDate.toString().split(' ')[0]),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AddEventDialog.show(context, _addEvent);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

