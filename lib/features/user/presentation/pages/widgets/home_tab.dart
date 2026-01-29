import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../core/app_theme.dart';
import '../../../../../../core/models/ad_model.dart';
import '../../../../../../core/models/user_model.dart';
import '../../../../../../core/models/visitor_model.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/api_service.dart';
import 'raise_complaint_dialog.dart';
import 'report_kid_exit_sheet.dart';
import '../visitors_page.dart';
import '../vehicles_page.dart';
import '../family_page.dart';
import '../gate_approval_page.dart';
import '../security_list_page.dart';
import '../unit_visitor_list_page.dart';

class HomeTab extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onSwitchToComplaints;

  const HomeTab({
    super.key,
    required this.user,
    this.onSwitchToComplaints,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  List<AdModel> _ads = [];
  bool _adsLoading = true;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    setState(() => _adsLoading = true);
    try {
      final response = await _apiService.getAds();
      if (mounted && response['success'] == true && response['ads'] != null) {
        setState(() {
          _ads = (response['ads'] as List)
              .map((e) => AdModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _adsLoading = false;
        });
        if (_ads.length > 1) _startCarouselTimer();
      } else {
        if (mounted) setState(() => _adsLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _adsLoading = false);
    }
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients || _ads.isEmpty) return;
      final next = (_pageController.page?.round() ?? 0) + 1;
      if (next >= _ads.length) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _navigateToComingSoon(String featureName) {
    Navigator.pushNamed(
      context,
      AppRoutes.featureComingSoon,
      arguments: {'featureName': featureName},
    );
  }

  void _showRaiseComplaintDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RaiseComplaintDialog(
        userId: widget.user.id,
        initialType: null,
      ),
    );
  }

  void _navigateToVisitors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => VisitorsPage(user: widget.user),
      ),
    );
  }

  void _navigateToVehicles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => VehiclesPage(user: widget.user),
      ),
    );
  }

  void _navigateToFamily() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => FamilyPage(user: widget.user),
      ),
    );
  }

  void _navigateToGateApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const GateApprovalPage(),
      ),
    );
  }

  void _navigateToSecurityList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const SecurityListPage(),
      ),
    );
  }

  void _navigateToCabAutoList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => UnitVisitorListPage(
          title: 'Cab / Auto',
          visitorTypes: [VisitorType.cabTaxi],
        ),
      ),
    );
  }

  void _navigateToAllowedDeliveryList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => UnitVisitorListPage(
          title: 'Allowed Delivery',
          visitorTypes: [VisitorType.deliveryBoy, VisitorType.courier],
        ),
      ),
    );
  }

  void _navigateToDailyHelpList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => UnitVisitorListPage(
          title: 'My Daily Help',
          visitorTypes: [VisitorType.maid],
        ),
      ),
    );
  }

  void _showReportKidExitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ReportKidExitSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdsCarousel(),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Quick Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickOptionsGrid(),
        ],
      ),
    );
  }

  Widget _buildAdsCarousel() {
    if (_adsLoading) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: ad.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickOptionsGrid() {
    const options = [
      _QuickOption('Home', Icons.home_rounded, _Action.home),
      _QuickOption('Complaints', Icons.report_problem_rounded, _Action.complaints),
      _QuickOption('Payments', Icons.payment_rounded, _Action.payments),
      // _QuickOption('Helpdesk', Icons.help_rounded, _Action.helpDesk),
      _QuickOption('Amenities', Icons.spa_rounded, _Action.amenities),
      _QuickOption('Security', Icons.security_rounded, _Action.securityList),
      // _QuickOption('Raise Alert', Icons.warning_rounded, _Action.raiseAlert),
      _QuickOption('Gate Approval', Icons.how_to_reg_rounded, _Action.gateApproval),
      _QuickOption('Invite Guest', Icons.person_add_rounded, _Action.inviteGuest),
      _QuickOption('Cab/Auto', Icons.local_taxi_rounded, _Action.cabAuto),
      _QuickOption('Allowed Delivery', Icons.delivery_dining_rounded, _Action.allowedDelivery),

      _QuickOption('Call Security', Icons.phone_rounded, _Action.securityList),
      _QuickOption('Message Guard', Icons.message_rounded, _Action.comingSoon),
      _QuickOption('My Pass', Icons.badge_rounded, _Action.comingSoon),
      _QuickOption('My Family', Icons.family_restroom_rounded, _Action.family),
      _QuickOption('My Daily Help', Icons.cleaning_services_rounded, _Action.dailyHelp),
      _QuickOption('My Vehicles', Icons.directions_car_rounded, _Action.vehicles),
      _QuickOption('Help and Support', Icons.support_agent_rounded, _Action.helpDesk),
      _QuickOption('Kid Exit', Icons.child_care_rounded, _Action.kidExit),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = 4;
        final spacing = 8.0;
        final availableWidth = constraints.maxWidth;
        final itemWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        final itemHeight = itemWidth * 1.1; // Slightly taller for better content fit
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final o = options[index];
            return _QuickOptionTile(
              title: o.title,
              icon: o.icon,
              onTap: () => _handleQuickOptionTap(o),
            );
          },
        );
      },
    );
  }

  void _handleQuickOptionTap(_QuickOption o) {
    switch (o.action) {
      case _Action.home:
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        break;
      case _Action.complaints:
        widget.onSwitchToComplaints?.call();
        break;
      case _Action.raiseAlert:
        _showRaiseComplaintDialog();
        break;
      case _Action.gateApproval:
        _navigateToGateApproval();
        break;
      case _Action.inviteGuest:
        _navigateToVisitors();
        break;
      case _Action.vehicles:
        _navigateToVehicles();
        break;
      case _Action.family:
        _navigateToFamily();
        break;
      case _Action.securityList:
        _navigateToSecurityList();
        break;
      case _Action.amenities:
        Navigator.pushNamed(context, AppRoutes.amenities);
        break;
      case _Action.payments:
        Navigator.pushNamed(context, AppRoutes.payments);
        break;
      case _Action.helpDesk:
        Navigator.pushNamed(context, AppRoutes.support);
        break;
      case _Action.cabAuto:
        _navigateToCabAutoList();
        break;
      case _Action.allowedDelivery:
        _navigateToAllowedDeliveryList();
        break;
      case _Action.dailyHelp:
        _navigateToDailyHelpList();
        break;
      case _Action.kidExit:
        _showReportKidExitSheet();
        break;
      case _Action.comingSoon:
        _navigateToComingSoon(o.title);
        break;
    }
  }
}

enum _Action { home, complaints, raiseAlert, gateApproval, inviteGuest, vehicles, family, securityList, amenities, payments, helpDesk, cabAuto, allowedDelivery, dailyHelp, kidExit, comingSoon }

class _QuickOption {
  final String title;
  final IconData icon;
  final _Action action;
  const _QuickOption(this.title, this.icon, this.action);
}

class _QuickOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickOptionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 22),
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
