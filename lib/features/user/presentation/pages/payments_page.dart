import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/models/payment_model.dart';
import '../../../../core/services/api_service.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final ApiService _api = ApiService();
  List<PaymentModel> _pending = [];
  List<PaymentModel> _paid = [];
  bool _isLoading = true;
  String? _filterMonth;
  int? _filterYear;
  Razorpay? _razorpay;
  String? _payingPaymentId;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _onRazorpaySuccess(PaymentSuccessResponse response) {
    if (_payingPaymentId == null) return;
    final paymentId = _payingPaymentId!;
    _payingPaymentId = null;
    _api.completePayment(
      paymentId,
      transactionId: response.paymentId,
      paymentMethod: 'online',
    ).then((res) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPayments();
      }
    }).catchError((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded; please refresh.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPayments();
      }
    });
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    _payingPaymentId = null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getMyPayments(
        month: _filterMonth,
        year: _filterYear,
      );
      if (mounted && res['success'] == true && res['payments'] != null) {
        final list = (res['payments'] as List)
            .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _pending = list.where((p) => p.status == 'pending').toList();
          _paid = list.where((p) => p.status == 'paid').toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _payNow(PaymentModel p) async {
    final orderRes = await _api.createRazorpayOrder(p.id);
    if (!mounted) return;
    if (orderRes['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderRes['error'] ?? 'Could not create order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final orderId = orderRes['orderId'] as String?;
    final amount = orderRes['amount'] as int? ?? (p.displayAmount * 100).round();
    final keyId = orderRes['keyId'] as String? ?? '';

    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _payingPaymentId = p.id;
    final options = {
      'key': keyId.isNotEmpty ? keyId : ApiConfig.razorpayKey,
      'amount': amount,
      'order_id': orderId,
      'name': 'Apartment Management',
      'description': '${p.month} ${p.year}',
    };
    try {
      _razorpay?.open(options);
    } catch (e) {
      _payingPaymentId = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              const SizedBox(height: 16),
              if (p.lineItems.isNotEmpty) ...[
                const Text(
                  'Breakdown',
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
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
              if (p.status == 'pending') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _payNow(p);
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Pay now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              if (p.paymentDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Paid on ${p.paymentDate.toString().split(' ').first}',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
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
                          value: _monthNames[i],
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
                : RefreshIndicator(
                    onRefresh: _loadPayments,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (_pending.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ),
                          ..._pending.map((p) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  onTap: () => _showDetail(p),
                                  title: Text(
                                    '${p.month} ${p.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '₹${p.displayAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _payNow(p),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Pay now'),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 24),
                        ],
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Payment history',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                        if (_paid.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No paid payments yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                        else
                          ..._paid.map((p) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  onTap: () => _showDetail(p),
                                  title: Text(
                                    '${p.month} ${p.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '₹${p.displayAmount.toStringAsFixed(2)} · Paid ${p.paymentDate != null ? p.paymentDate.toString().split(' ').first : ""}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              )),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
