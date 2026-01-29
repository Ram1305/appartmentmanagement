import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../features/maintenance/presentation/pages/maintenance_page.dart';

/// Wraps user or security dashboard: if app subscription is inactive,
/// shows [MaintenancePage] instead of [child].
class MaintenanceRouteGuard extends StatefulWidget {
  final Widget child;

  const MaintenanceRouteGuard({super.key, required this.child});

  @override
  State<MaintenanceRouteGuard> createState() => _MaintenanceRouteGuardState();
}

class _MaintenanceRouteGuardState extends State<MaintenanceRouteGuard> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final res = await _api.getSubscriptionAppActive();
    if (mounted) {
      setState(() {
        _loading = false;
        _active = res['active'] == true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_active) {
      return const MaintenancePage();
    }
    return widget.child;
  }
}
