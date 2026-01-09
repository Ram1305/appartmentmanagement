import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing and using this apartment management application, you accept and agree to be bound by the terms and conditions of use.',
            ),
            _buildSection(
              context,
              '2. User Responsibilities',
              'Users are responsible for maintaining the confidentiality of their account credentials and for all activities that occur under their account.',
            ),
            _buildSection(
              context,
              '3. Visitor Management',
              'All visitors must be registered through the application. Users are responsible for their visitors\' conduct and compliance with apartment rules.',
            ),
            _buildSection(
              context,
              '4. Payment Terms',
              'Rent and maintenance charges must be paid on time as per the schedule. Late payments may incur penalties as per the apartment policies.',
            ),
            _buildSection(
              context,
              '5. Complaints and Grievances',
              'Complaints should be submitted through the official channels in the application. All complaints will be addressed as per the apartment management policies.',
            ),
            _buildSection(
              context,
              '6. Privacy Policy',
              'Your personal information will be used only for apartment management purposes and will not be shared with third parties without your consent.',
            ),
            _buildSection(
              context,
              '7. Code of Conduct',
              'Users must adhere to apartment rules and regulations. Violation of rules may result in warnings or account suspension.',
            ),
            _buildSection(
              context,
              '8. Modifications',
              'The apartment management reserves the right to modify these terms and conditions at any time. Users will be notified of significant changes.',
            ),
            const SizedBox(height: 32),
            Text(
              'Last Updated: ${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
