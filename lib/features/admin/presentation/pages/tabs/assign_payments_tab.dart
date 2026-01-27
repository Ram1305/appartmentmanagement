import 'package:flutter/material.dart';
import '../../../../../../core/app_theme.dart';
import '../../../../../../core/models/payment_model.dart';
import '../../../../../../core/models/user_model.dart';
import '../../../../../../core/services/api_service.dart';
import '../../bloc/admin_bloc.dart';

const List<String> _paymentTypes = [
  'Maintenance',
  'Rent',
  'Parking',
  'Amenities usage',
  'Penalty',
  'Electricity',
  'Water',
];

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class AssignPaymentsTab extends StatefulWidget {
  final AdminLoaded state;
  const AssignPaymentsTab({required this.state, super.key});

  @override
  State<AssignPaymentsTab> createState() => _AssignPaymentsTabState();
}

class _AssignPaymentsTabState extends State<AssignPaymentsTab> {
  final ApiService _api = ApiService();
  List<PaymentModel> _payments = [];
  List<UserModel> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _loadUsers();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getAllPayments();
      if (mounted && res['success'] == true && res['payments'] != null) {
        setState(() {
          _payments = (res['payments'] as List)
              .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUsers() async {
    try {
      final res = await _api.getAllUsers();
      if (mounted && res['success'] == true && res['users'] != null) {
        final list = (res['users'] as List)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .where((u) =>
                u.status == AccountStatus.approved &&
                u.block != null &&
                u.block!.isNotEmpty &&
                u.roomNumber != null &&
                u.roomNumber!.isNotEmpty)
            .toList();
        setState(() => _users = list);
      }
    } catch (_) {}
  }

  void _showAddPaymentSheet() {
    UserModel? selectedUser;
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    final amounts = <String, double>{};
    final controllers = <String, TextEditingController>{};
    for (final t in _paymentTypes) {
      amounts[t] = 0;
      controllers[t] = TextEditingController();
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          double total = 0;
          for (final v in amounts.values) {
            total += v;
          }
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Add Payment',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // User (unit) selection
                  DropdownButtonFormField<UserModel>(
                    decoration: InputDecoration(
                      labelText: 'House (Block – Floor – Room)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    value: selectedUser,
                    items: _users
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(
                                '${u.block ?? ""} – ${u.floor ?? ""} – ${u.roomNumber ?? ""} (${u.name})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedUser = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Month',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          value: selectedMonth,
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text(_monthNames[i]),
                            ),
                          ),
                          onChanged: (v) =>
                              setModalState(() => selectedMonth = v ?? selectedMonth),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          value: selectedYear,
                          items: () {
                            final years = [
                              DateTime.now().year - 1,
                              DateTime.now().year,
                              DateTime.now().year + 1,
                            ];
                            if (!years.contains(selectedYear)) years.add(selectedYear);
                            years.sort();
                            return years
                                .map((y) => DropdownMenuItem(
                                      value: y,
                                      child: Text('$y'),
                                    ))
                                .toList();
                          }(),
                          onChanged: (v) =>
                              setModalState(() => selectedYear = v ?? selectedYear),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Line items',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._paymentTypes.map((type) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                type,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: controllers[type],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (v) {
                                  final n = double.tryParse(v) ?? 0;
                                  setModalState(() => amounts[type] = n);
                                },
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            for (final c in controllers.values) {
                              c.dispose();
                            }
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedUser == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Select a house'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            final lineItems = <Map<String, dynamic>>[];
                            for (final type in _paymentTypes) {
                              final amt = double.tryParse(controllers[type]?.text ?? '') ?? 0;
                              if (amt > 0) {
                                lineItems.add({
                                  'type': type,
                                  'amount': amt,
                                });
                              }
                            }
                            if (lineItems.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Add at least one amount'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            final totalFromItems = lineItems.fold<double>(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
                            if (totalFromItems <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Add at least one amount'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            for (final c in controllers.values) {
                              c.dispose();
                            }
                            Navigator.pop(ctx);
                            final res = await _api.assignPayment(
                              userId: selectedUser!.id,
                              month: _monthNames[selectedMonth - 1],
                              year: selectedYear,
                              lineItems: lineItems,
                            );
                            if (!mounted) return;
                            if (res['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment assigned successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadPayments();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['error'] ?? 'Failed'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Add payment'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assign Payments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddPaymentSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add payment'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No payments assigned yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _showAddPaymentSheet,
                              icon: const Icon(Icons.add),
                              label: const Text('Add payment'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPayments,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final p = _payments[index];
                            final unit = [
                              p.userBlock,
                              p.userFloor,
                              p.userRoomNumber,
                            ].where((e) => e != null && e.isNotEmpty).join(' – ');
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  (p.userName ?? 'User') +
                                      (unit.isNotEmpty ? ' · $unit' : ''),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${p.month} ${p.year} · ₹${p.displayAmount.toStringAsFixed(2)} · ${p.status}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.status == 'paid'
                                        ? Colors.green
                                        : AppTheme.textColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
