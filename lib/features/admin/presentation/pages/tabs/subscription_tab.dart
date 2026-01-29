import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../../core/config/api_config.dart';
import '../../../../../core/models/subscription_plan_model.dart';
import '../../../../../core/models/user_model.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';

class SubscriptionTab extends StatefulWidget {
  const SubscriptionTab({super.key});

  @override
  State<SubscriptionTab> createState() => _SubscriptionTabState();
}

class _SubscriptionTabState extends State<SubscriptionTab> {
  final ApiService _api = ApiService();
  List<SubscriptionPlanModel> _plans = [];
  bool _loadingPlans = true;
  bool _showPlans = false;
  Razorpay? _razorpay;
  String? _pendingOrderId;
  String? _pendingPlanId;

  static const List<Color> _planColors = [
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFE8F5E9),
    Color(0xFFFFF8E1),
    Color(0xFFFCE4EC),
  ];

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _loadingPlans = true);
    try {
      final res = await _api.getSubscriptionPlans();
      if (mounted && res['success'] == true && res['plans'] != null) {
        final list = (res['plans'] as List)
            .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _plans = list;
          _loadingPlans = false;
        });
      } else {
        if (mounted) setState(() => _loadingPlans = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  void _onRazorpaySuccess(PaymentSuccessResponse response) {
    final orderId = _pendingOrderId;
    final planId = _pendingPlanId;
    _pendingOrderId = null;
    _pendingPlanId = null;
    if (orderId == null) return;
    final paymentId = response.paymentId ?? '';
    final signature = (response as dynamic).signature?.toString() ?? '';
    _api
        .verifySubscription(
          orderId: orderId,
          razorpayPaymentId: paymentId,
          signature: signature,
        )
        .then((res) {
      if (!mounted) return;
      if (res['success'] == true) {
        context.read<AuthBloc>().add(CheckAuthStatusEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error']?.toString() ?? 'Verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    _pendingOrderId = null;
    _pendingPlanId = null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _payNow(SubscriptionPlanModel plan) async {
    final orderRes = await _api.createSubscriptionOrder(plan.id);
    if (!mounted) return;
    if (orderRes['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderRes['error']?.toString() ?? 'Could not create order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final orderId = orderRes['orderId'] as String?;
    final amount = orderRes['amount'] as int? ?? (plan.amount * 100).round();
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
    _pendingOrderId = orderId;
    _pendingPlanId = plan.id;
    final options = {
      'key': keyId.isNotEmpty ? keyId : ApiConfig.razorpayKey,
      'amount': amount,
      'order_id': orderId,
      'name': 'Apartment Management',
      'description': plan.name,
    };
    try {
      _razorpay?.open(options);
    } catch (e) {
      _pendingOrderId = null;
      _pendingPlanId = null;
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

  Future<void> _showPlanHistory(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        title: Text('Plan History'),
        content: SizedBox(
          width: double.maxFinite,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    try {
      final res = await _api.getSubscriptionPlansHistory();
      if (!mounted) return;
      Navigator.of(context).pop();
      if (res['success'] != true || res['plans'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error']?.toString() ?? 'Failed to load plan history'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final list = (res['plans'] as List)
          .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Plan History'),
          content: SizedBox(
            width: double.maxFinite,
            child: list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No plans in history.')),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: list.asMap().entries.map((entry) {
                        final plan = entry.value;
                        final colorStr = plan.color;
                        final color = colorStr != null && colorStr.isNotEmpty
                            ? _parseColor(colorStr)
                            : _planColors[entry.key % _planColors.length];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          color: color.withOpacity(0.6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        plan.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        plan.isActive ? 'Active' : 'Inactive',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: plan.isActive
                                          ? Colors.green.shade100
                                          : Colors.grey.shade300,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${plan.amount.toStringAsFixed(0)} · ${plan.daysValidity} days',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                if (plan.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    plan.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                                if (plan.createdAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${_formatDate(plan.createdAt!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev != curr,
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final isAdmin = user?.userType == UserType.admin;
        final hasSubscription = isAdmin && (user?.subscriptionStatus == true);
        final daysLeft = user?.daysLeft ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (hasSubscription)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subscription days left: $daysLeft',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (user?.subscriptionEndsAt != null)
                              Text(
                                'Valid until: ${_formatDate(user!.subscriptionEndsAt!)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Activate your own plan first',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Subscribe to a plan below to enable the app for residents and security.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _showPlans = !_showPlans);
                        if (_showPlans && !_loadingPlans) _loadPlans();
                      },
                      icon: Icon(_showPlans ? Icons.expand_less : Icons.add_circle_outline),
                      label: Text(_showPlans ? 'Hide plans' : 'Add subscription'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showPlanHistory(context),
                    icon: const Icon(Icons.history, size: 20),
                    label: const Text('Plan History'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_showPlans) ...[
                if (_loadingPlans)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_plans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No plans available from the server.',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Run backend seed: node backend/scripts/seedSubscriptionPlans.js',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _plans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      final colorStr = plan.color;
                      final color = colorStr != null && colorStr.isNotEmpty
                          ? _parseColor(colorStr)
                          : _planColors[index % _planColors.length];
                      return Card(
                        elevation: 1,
                        color: color,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${plan.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${plan.daysValidity} days validity',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              if (plan.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  plan.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _payNow(plan),
                                  icon: const Icon(Icons.payment, size: 20),
                                  label: const Text('Pay Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Color _parseColor(String hex) {
    try {
      final c = hex.replaceFirst('#', '');
      if (c.length == 6) {
        return Color(int.parse('FF$c', radix: 16));
      }
      if (c.length == 8) {
        return Color(int.parse(c, radix: 16));
      }
    } catch (_) {}
    return _planColors.first;
  }
}
