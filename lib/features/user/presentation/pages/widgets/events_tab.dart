import 'package:flutter/material.dart';
import '../../../../../../core/app_theme.dart';

class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEventCard(
            'Diwali Celebration',
            DateTime.now().add(const Duration(days: 15)).toString().split(' ')[0],
            'Grand Diwali celebration in the community hall with lights, sweets, and cultural programs',
            Icons.celebration,
            AppTheme.accentColor,
          ),
          _buildEventCard(
            'Holi Festival',
            DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0],
            'Colorful Holi celebration with traditional music and delicious food',
            Icons.palette,
            AppTheme.secondaryColor,
          ),
          _buildEventCard(
            'Community Meeting',
            DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0],
            'Monthly community meeting to discuss apartment matters and maintenance',
            Icons.event,
            AppTheme.primaryColor,
          ),
          _buildEventCard(
            'Ganesh Chaturthi',
            DateTime.now().add(const Duration(days: 45)).toString().split(' ')[0],
            'Ganesh Chaturthi celebration with puja and cultural activities',
            Icons.temple_hindu,
            AppTheme.secondaryColor,
          ),
          _buildEventCard(
            'Maintenance Day',
            DateTime.now().add(const Duration(days: 10)).toString().split(' ')[0],
            'Scheduled maintenance work for all blocks - water supply will be affected',
            Icons.build,
            AppTheme.errorColor,
          ),
          _buildEventCard(
            'Annual General Meeting',
            DateTime.now().add(const Duration(days: 20)).toString().split(' ')[0],
            'Annual General Meeting (AGM) to discuss yearly activities and budget',
            Icons.groups,
            AppTheme.primaryColor,
          ),
          _buildEventCard(
            'Dussehra Celebration',
            DateTime.now().add(const Duration(days: 60)).toString().split(' ')[0],
            'Dussehra celebration with Ramlila and cultural programs',
            Icons.theater_comedy,
            AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(String title, String date, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textColor.withOpacity(0.8),
                      height: 1.4,
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
}


