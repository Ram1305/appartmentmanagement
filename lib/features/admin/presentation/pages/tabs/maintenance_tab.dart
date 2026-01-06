import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/models/maintenance_model.dart';
import '../../bloc/admin_bloc.dart';

class MaintenanceTab extends StatefulWidget {
  final AdminLoaded state;
  const MaintenanceTab({required this.state});
  @override
  State<MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<MaintenanceTab> {
  List<MaintenanceModel> _maintenanceList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMaintenance();
  }

  Future<void> _loadMaintenance() async {
    setState(() => _isLoading = true);
    final apiService = ApiService();
    final response = await apiService.getAllMaintenance();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['success'] == true && response['maintenance'] != null) {
          final List<dynamic> maintenanceData = response['maintenance'];
          _maintenanceList = maintenanceData
              .map((item) => MaintenanceModel.fromJson(item))
              .toList();
        }
      });
    }
  }

  void _showAddMaintenanceDialog(BuildContext context) {
    final amountController = TextEditingController();
    final monthController = TextEditingController();
    final yearController = TextEditingController();
    final apiService = ApiService();

    // Set current month and year as defaults
    final now = DateTime.now();
    monthController.text = now.month.toString();
    yearController.text = now.year.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Add Maintenance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter maintenance details',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
                TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
                TextField(
                controller: monthController,
                decoration: InputDecoration(
                  labelText: 'Month (1-12)',
                  prefixIcon: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: yearController,
                decoration: InputDecoration(
                  labelText: 'Year',
                  prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
              onPressed: () {
                        amountController.dispose();
                        monthController.dispose();
                        yearController.dispose();
                  Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (amountController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter amount'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final amount = double.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final monthNum = int.tryParse(monthController.text.trim());
                        if (monthNum == null || monthNum < 1 || monthNum > 12) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid month (1-12)'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final year = int.tryParse(yearController.text.trim());
                        if (year == null || year < 2000 || year > 2100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid year'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final monthNames = [
                          'January', 'February', 'March', 'April', 'May', 'June',
                          'July', 'August', 'September', 'October', 'November', 'December'
                        ];

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Adding maintenance...'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );

                        final response = await apiService.setMaintenance(
                          amount: amount,
                          month: monthNames[monthNum - 1],
                          year: year,
                        );

                        amountController.dispose();
                        monthController.dispose();
                        yearController.dispose();

    if (mounted) {
                          if (response['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Maintenance added successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadMaintenance();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(response['error'] ?? 'Failed to add maintenance'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Add Maintenance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMaintenanceDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Maintenance'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadMaintenance,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        if (_maintenanceList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total Maintenance Records: ${_maintenanceList.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _maintenanceList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: AppTheme.textColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No maintenance records yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textColor.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showAddMaintenanceDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Maintenance'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMaintenance,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _maintenanceList.length,
                        itemBuilder: (context, index) {
                          final maintenance = _maintenanceList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  maintenance.isActive
                                      ? AppTheme.primaryColor.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.05),
                                  maintenance.isActive
                                      ? AppTheme.secondaryColor.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.02),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: maintenance.isActive
                                    ? AppTheme.primaryColor.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                width: 1.5,
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: maintenance.isActive
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.currency_rupee,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                'â‚¹${maintenance.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          size: 12,
                                          color: AppTheme.textColor.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${maintenance.month} ${maintenance.year}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          maintenance.isActive ? Icons.check_circle : Icons.cancel,
                                          size: 12,
                                          color: maintenance.isActive ? Colors.green : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          maintenance.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: maintenance.isActive ? Colors.green : Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: maintenance.isActive
                                      ? AppTheme.primaryColor.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  maintenance.isActive ? 'ACTIVE' : 'INACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: maintenance.isActive
                                        ? AppTheme.primaryColor
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
