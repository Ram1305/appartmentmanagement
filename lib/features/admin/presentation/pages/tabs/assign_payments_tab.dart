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

/// Sheet content as StatefulWidget so [TextEditingController]s are disposed
/// in [dispose], not in [whenComplete], avoiding "used after disposed" when
/// the route is still rebuilding during pop.
class _AddPaymentSheetContent extends StatefulWidget {
  final List<UserModel> users;
  final ApiService api;
  final BuildContext scaffoldContext;
  final VoidCallback onSuccess;

  const _AddPaymentSheetContent({
    required this.users,
    required this.api,
    required this.scaffoldContext,
    required this.onSuccess,
  });

  @override
  State<_AddPaymentSheetContent> createState() => _AddPaymentSheetContentState();
}

class _AddPaymentSheetContentState extends State<_AddPaymentSheetContent> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _amounts = {};
  UserModel? _selectedUser;
  late int _selectedMonth;
  late int _selectedYear;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
    for (final t in _paymentTypes) {
      _amounts[t] = 0;
      _controllers[t] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final v in _amounts.values) {
      total += v;
    }
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24,
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
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: DropdownButtonFormField<UserModel>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'House (Block – Floor – Room)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    value: _selectedUser,
                    items: widget.users
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(
                                '${u.block ?? ""} – ${u.floor ?? ""} – ${u.roomNumber ?? ""} (${u.name})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUser = v),
                  ),
                );
              },
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
                    value: _selectedMonth,
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_monthNames[i]),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _selectedMonth = v ?? _selectedMonth),
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
                    value: _selectedYear,
                    items: () {
                      final years = [
                        DateTime.now().year - 1,
                        DateTime.now().year,
                        DateTime.now().year + 1,
                      ];
                      if (!years.contains(_selectedYear)) years.add(_selectedYear);
                      years.sort();
                      return years
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text('$y'),
                              ))
                          .toList();
                    }(),
                    onChanged: (v) =>
                        setState(() => _selectedYear = v ?? _selectedYear),
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
                          controller: _controllers[type],
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
                            setState(() => _amounts[type] = n);
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
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: _isSubmitting
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Add payment'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a house'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final lineItems = <Map<String, dynamic>>[];
    for (final type in _paymentTypes) {
      final amt = double.tryParse(_controllers[type]?.text ?? '') ?? 0;
      if (amt > 0) {
        lineItems.add({'type': type, 'amount': amt});
      }
    }
    if (lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final totalFromItems = lineItems.fold<double>(
        0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
    if (totalFromItems <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final res = await widget.api.assignPayment(
        userId: _selectedUser!.id,
        month: _monthNames[_selectedMonth - 1],
        year: _selectedYear,
        lineItems: lineItems,
      );
      if (!mounted) return;
      final success = res['success'] == true;
      final raw = res['error'] ?? res['message'];
      final message = (raw is String && raw.trim().isNotEmpty)
          ? raw
          : 'Failed to assign payment';
      if (success) {
        Navigator.pop(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onSuccess();
          if (widget.scaffoldContext.mounted) {
            ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
              const SnackBar(
                content: Text('Payment assigned successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final err = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.isNotEmpty ? err : 'Failed to assign payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

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
      debugPrint('[AssignPaymentsTab] _loadPayments: success=${res['success']}, payments count=${(res['payments'] as List?)?.length ?? 0}');
      if (mounted && res['success'] == true && res['payments'] != null) {
        final list = (res['payments'] as List)
            .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint('[AssignPaymentsTab] parsed ${list.length} payments: ${list.map((p) => '${p.month}/${p.year} ${p.status}').join(', ')}');
        setState(() => _payments = list);
      }
    } catch (e, st) {
      debugPrint('[AssignPaymentsTab] _loadPayments error: $e\n$st');
    }
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPaymentSheetContent(
        users: _users,
        api: _api,
        scaffoldContext: context,
        onSuccess: _loadPayments,
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
