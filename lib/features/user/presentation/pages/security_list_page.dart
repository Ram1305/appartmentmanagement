import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/services/api_service.dart';

class SecurityListPage extends StatefulWidget {
  const SecurityListPage({super.key});

  @override
  State<SecurityListPage> createState() => _SecurityListPageState();
}

class _SecurityListPageState extends State<SecurityListPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _securityList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSecurityList();
  }

  Future<void> _loadSecurityList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _apiService.getSecurityList();
      if (mounted) {
        if (response['success'] == true && response['security'] != null) {
          setState(() {
            _securityList = List<Map<String, dynamic>>.from(
              (response['security'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
            );
            _loading = false;
          });
        } else {
          setState(() {
            _error = response['error'] as String? ?? 'Failed to load security list';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _callSecurity(String mobileNumber) async {
    final uri = Uri.parse('tel:$mobileNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open dialer'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not place call: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadSecurityList,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.orange.shade700),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textColor.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSecurityList,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _securityList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security_rounded, size: 64, color: AppTheme.textColor.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No security staff listed',
                            style: TextStyle(color: AppTheme.textColor.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSecurityList,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _securityList.length,
                        itemBuilder: (context, index) {
                          final s = _securityList[index];
                          final name = s['name'] as String? ?? 'Security';
                          final mobile = s['mobileNumber'] as String? ?? '';
                          final profilePic = s['profilePic'] as String?;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                                backgroundImage: profilePic != null && profilePic.isNotEmpty
                                    ? CachedNetworkImageProvider(profilePic)
                                    : null,
                                child: profilePic == null || profilePic.isEmpty
                                    ? Icon(Icons.person, size: 32, color: AppTheme.primaryColor)
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              subtitle: mobile.isNotEmpty
                                  ? Text(
                                      mobile,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textColor.withOpacity(0.7),
                                      ),
                                    )
                                  : null,
                              trailing: Material(
                                color: AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: mobile.isNotEmpty
                                      ? () => _callSecurity(mobile)
                                      : null,
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(Icons.call, color: Colors.white, size: 24),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
