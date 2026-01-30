import 'dart:ui';
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
  Map<String, dynamic>? _mySubscription;
  bool _loadingMySubscription = false;

  static const List<Color> _planColors = [
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFE8F5E9),
    Color(0xFFFFF8E1),
    Color(0xFFFCE4EC),
  ];

  static const List<Color> _gradientStart = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
    Color(0xFFf093fb),
  ];
  static const List<Color> _gradientEnd = [
    Color(0xFF764ba2),
    Color(0xFF667eea),
    Color(0xFFf5576c),
  ];

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _loadMySubscription();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
  }

  Future<void> _loadMySubscription() async {
    if (_loadingMySubscription) return;
    setState(() => _loadingMySubscription = true);
    try {
      final res = await _api.getMySubscription();
      if (mounted && res['success'] == true) {
        setState(() {
          _mySubscription = res;
          _loadingMySubscription = false;
        });
      } else {
        if (mounted) setState(() => _loadingMySubscription = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMySubscription = false);
    }
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
        _loadMySubscription();
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_gradientStart[0], _gradientEnd[0]],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _gradientStart[0].withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.history_edu, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan History',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          Text(
                            'Your subscribed plans & catalog',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    _api.getMySubscription(),
                    _api.getSubscriptionPlansHistory(),
                  ]),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'Failed to load data',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final mySub = snap.data![0] as Map<String, dynamic>;
                    final historyRes = snap.data![1] as Map<String, dynamic>;
                    final hasMySub = mySub['success'] == true;
                    final myPlan = hasMySub && mySub['plan'] != null
                        ? mySub['plan'] as Map<String, dynamic>?
                        : null;
                    final subStatus = hasMySub && (mySub['subscriptionStatus'] == true);
                    final daysLeft = hasMySub ? (mySub['daysLeft'] as int? ?? 0) : 0;
                    final endsAt = hasMySub && mySub['subscriptionEndsAt'] != null
                        ? DateTime.tryParse(mySub['subscriptionEndsAt'].toString())
                        : null;
                    final historyPlans = (historyRes['success'] == true && historyRes['plans'] != null)
                        ? (historyRes['plans'] as List)
                            .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
                            .toList()
                        : <SubscriptionPlanModel>[];

                    return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            // My subscribed plan section
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.card_membership, size: 20, color: _gradientStart[0]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your subscribed plan',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (subStatus && myPlan != null)
                              _buildMySubscribedPlanCard(
                                context,
                                planName: myPlan['name']?.toString() ?? 'Current plan',
                                daysValidity: (myPlan['daysValidity'] is int)
                                    ? myPlan['daysValidity'] as int
                                    : (myPlan['daysValidity'] as num?)?.toInt() ?? 0,
                                description: myPlan['description']?.toString() ?? '',
                                daysLeft: daysLeft,
                                endsAt: endsAt,
                              )
                            else
                              _buildNoSubscriptionCard(context),
                            const SizedBox(height: 24),
                            // All plans catalog
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.list_alt, size: 20, color: _gradientStart[1]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'All plans',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (historyPlans.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                alignment: Alignment.center,
                                child: Text(
                                  'No plans in catalog.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              )
                            else
                              ...historyPlans.asMap().entries.map((entry) {
                                final plan = entry.value;
                                final colorStr = plan.color;
                                final color = colorStr != null && colorStr.isNotEmpty
                                    ? _parseColor(colorStr)
                                    : _planColors[entry.key % _planColors.length];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildPlanHistoryCatalogCard(context, plan, color),
                                );
                              }),
                          ],
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMySubscribedPlanCard(
    BuildContext context, {
    required String planName,
    required int daysValidity,
    required String description,
    required int daysLeft,
    DateTime? endsAt,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStart[0], _gradientEnd[0]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _gradientStart[0].withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${daysValidity} days validity',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$daysLeft days left',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
                if (endsAt != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.event_available, size: 16, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(width: 6),
                      Text(
                        'Valid until ${_formatDate(endsAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline, color: Colors.orange.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No active subscription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subscribe to a plan from "Add subscription" to activate.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanHistoryCatalogCard(
    BuildContext context,
    SubscriptionPlanModel plan,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: _parseColor(plan.color ?? '#667eea'),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${plan.amount.toStringAsFixed(0)} · ${plan.daysValidity} days',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (plan.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    plan.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Chip(
            label: Text(
              plan.isActive ? 'Active' : 'Inactive',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            backgroundColor: plan.isActive
                ? Colors.green.shade100
                : Colors.grey.shade300,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
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

        return RefreshIndicator(
          onRefresh: () async {
            await _loadPlans();
            await _loadMySubscription();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // My subscription card
                _buildMySubscriptionCard(context, hasSubscription, daysLeft, user),
                const SizedBox(height: 20),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(14),
                        shadowColor: _gradientStart[0].withOpacity(0.3),
                        child: InkWell(
                          onTap: () {
                            setState(() => _showPlans = !_showPlans);
                            if (_showPlans && !_loadingPlans) _loadPlans();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _showPlans
                                    ? [Colors.grey.shade700, Colors.grey.shade800]
                                    : [_gradientStart[0], _gradientEnd[0]],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showPlans ? Icons.expand_less : Icons.add_circle_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _showPlans ? 'Hide plans' : 'Add subscription',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(14),
                      shadowColor: _gradientStart[1].withOpacity(0.25),
                      child: InkWell(
                        onTap: () => _showPlanHistory(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_gradientStart[1], _gradientEnd[1]],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_edu, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Plan History',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_showPlans) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.card_giftcard, color: _gradientStart[0], size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Available plans',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (_loadingPlans)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_plans.isEmpty)
                    _buildEmptyPlansMessage(context)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _plans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final plan = _plans[index];
                        final colorStr = plan.color;
                        final color = colorStr != null && colorStr.isNotEmpty
                            ? _parseColor(colorStr)
                            : _planColors[index % _planColors.length];
                        return _buildAddSubscriptionPlanCard(context, plan, color, index);
                      },
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMySubscriptionCard(
    BuildContext context,
    bool hasSubscription,
    int daysLeft,
    UserModel? user,
  ) {
    final planName = _mySubscription != null && _mySubscription!['plan'] != null
        ? (_mySubscription!['plan'] as Map<String, dynamic>)['name']?.toString()
        : null;
    if (_loadingMySubscription) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasSubscription
              ? [_gradientStart[0], _gradientEnd[0]]
              : [Colors.grey.shade600, Colors.grey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasSubscription ? _gradientStart[0] : Colors.grey).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hasSubscription ? Icons.verified_user : Icons.card_membership,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My subscription',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasSubscription
                              ? (planName ?? 'Active plan')
                              : 'No active plan',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasSubscription)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$daysLeft days left',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              if (hasSubscription && user?.subscriptionEndsAt != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.event_available, size: 18, color: Colors.white.withOpacity(0.95)),
                    const SizedBox(width: 8),
                    Text(
                      'Valid until ${_formatDate(user!.subscriptionEndsAt!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ],
              if (!hasSubscription) ...[
                const SizedBox(height: 14),
                Text(
                  'Subscribe to a plan below to enable the app for residents and security.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlansMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No plans available from the server.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Run: node backend/scripts/seedSubscriptionPlans.js',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddSubscriptionPlanCard(
    BuildContext context,
    SubscriptionPlanModel plan,
    Color color,
    int index,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: _parseColor(plan.color ?? '#667eea'),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plan.daysValidity} days validity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${plan.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                plan.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _payNow(plan),
                icon: const Icon(Icons.payment_rounded, size: 20),
                label: const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gradientStart[0],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: _gradientStart[0].withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
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
