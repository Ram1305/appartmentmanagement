import 'package:flutter/material.dart';
import '../../../../../../core/app_theme.dart';
import '../../../../../../core/models/payment_model.dart';
import '../../../../../../core/services/api_service.dart';
import '../../bloc/admin_bloc.dart';

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class PaymentsTab extends StatefulWidget {
  final AdminLoaded state;
  /// When non-null, [parentTabController] and [parentTabIndex] are used to
  /// refresh payments when the user switches to this tab (so newly added
  /// payments show in the Pending list).
  final TabController? parentTabController;
  final int? parentTabIndex;

  const PaymentsTab({
    required this.state,
    this.parentTabController,
    this.parentTabIndex,
    super.key,
  });

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  int? _filterMonth;
  int? _filterYear;
  VoidCallback? _parentTabListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPayments();
    final parent = widget.parentTabController;
    final index = widget.parentTabIndex;
    if (parent != null && index != null) {
      void listener() {
        if (parent.index == index && mounted) _loadPayments();
      }
      _parentTabListener = listener;
      parent.addListener(listener);
    }
  }

  @override
  void dispose() {
    if (_parentTabListener != null && widget.parentTabController != null) {
      widget.parentTabController!.removeListener(_parentTabListener!);
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      String? month;
      int? year;
      if (_filterMonth != null) month = _monthNames[_filterMonth! - 1];
      if (_filterYear != null) year = _filterYear;
      final status = _tabController.index == 0 ? 'pending' : 'paid';
      debugPrint('[PaymentsTab] _loadPayments: month=$month year=$year status=$status');
      final res = await _api.getAllPayments(month: month, year: year, status: status);
      debugPrint('[PaymentsTab] _loadPayments: success=${res['success']}, payments count=${(res['payments'] as List?)?.length ?? 0}');
      if (mounted && res['success'] == true && res['payments'] != null) {
        final list = (res['payments'] as List)
            .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint('[PaymentsTab] parsed ${list.length} payments: ${list.map((p) => '${p.month}/${p.year} ${p.status}').join(', ')}');
        setState(() => _payments = list);
      }
    } catch (e, st) {
      debugPrint('[PaymentsTab] _loadPayments error: $e\n$st');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onFilterOrTabChanged() {
    _loadPayments();
  }

  void _showDetail(PaymentModel p) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
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
              Text(
                '${p.month} ${p.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              if (p.userName != null)
                Text(
                  p.userName!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor.withOpacity(0.8),
                  ),
                ),
              if (p.userBlock != null || p.userRoomNumber != null)
                Text(
                  '${p.userBlock ?? ""} – ${p.userFloor ?? ""} – ${p.userRoomNumber ?? ""}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 16),
              if (p.lineItems.isNotEmpty) ...[
                const Text(
                  'Line items',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...p.lineItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.type),
                          Text('₹${item.amount.toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
                const Divider(),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Text(
                    '₹${p.displayAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.status == 'paid'
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.status == 'paid' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              if (p.paymentDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Paid on: ${p.paymentDate.toString().split(' ').first}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
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
        TabBar(
          controller: _tabController,
          onTap: (_) => _onFilterOrTabChanged(),
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Pending payments'),
            Tab(text: 'Completed payments'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  decoration: InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  value: _filterMonth,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_monthNames[i]),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _filterMonth = v;
                      _loadPayments();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  decoration: InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  value: _filterYear,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...List.generate(
                      5,
                      (i) => DateTime.now().year - 2 + i,
                    ).map((y) => DropdownMenuItem(value: y, child: Text('$y'))),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _filterYear = v;
                      _loadPayments();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _payments.isEmpty
                  ? Center(
                      child: Text(
                        _tabController.index == 0
                            ? 'No pending payments'
                            : 'No completed payments',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
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
                              onTap: () => _showDetail(p),
                              title: Text(
                                (p.userName ?? 'User') +
                                    (unit.isNotEmpty ? ' · $unit' : ''),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${p.month} ${p.year} · ₹${p.displayAmount.toStringAsFixed(2)}'
                                    + (p.paymentDate != null
                                        ? ' · Paid ${p.paymentDate.toString().split(' ').first}'
                                        : ''),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
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
