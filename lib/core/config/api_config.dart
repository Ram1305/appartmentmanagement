import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Production server URL (used in release builds).
  static const String _productionBaseUrl = 'http://72.61.236.154:5000/api';

  /// Local/debug server URL (used in debug builds). Change as needed:
  /// - Android emulator: 'http://10.0.2.2:5000/api'
  /// - iOS simulator: 'http://localhost:5000/api'
  /// - Physical device: 'http://YOUR_PC_IP:5000/api' (e.g. http://192.168.1.100:5000/api)
  static const String _debugBaseUrl = 'http://10.0.2.2:5000/api';

  /// Base URL: uses debug URL when running in debug mode, otherwise production.
  static String get baseUrl => kDebugMode ? _debugBaseUrl : _productionBaseUrl;

  static String get authBase => '$baseUrl/auth';

  // Auth endpoints
  static String get register => '$authBase/register';
  static String get registerAdmin => '$authBase/register-admin';
  static String get login => '$authBase/login';
  static String get sendOtp => '$authBase/send-otp';
  static String get verifyOtp => '$authBase/verify-otp';
  static String get forgotPassword => '$authBase/forgot-password';
  static String get resetPassword => '$authBase/reset-password';
  static String get getCurrentUser => '$authBase/me';
  static String get getAllUsers => '$authBase/users';

  // Block endpoints
  static String get blocksBase => '$baseUrl/blocks';
  static String get getAllBlocks => blocksBase;
  static String get getBlock => blocksBase; // Use with /:id
  static String get createBlock => blocksBase;
  static String get addFloor => blocksBase; // Use with /:id/floors
  static String get addRoom => blocksBase; // Use with /:blockId/floors/:floorId/rooms
  static String get updateBlock => blocksBase; // Use with /:id
  static String get updateFloor => blocksBase; // Use with /:blockId/floors/:floorId
  static String get deleteBlock => blocksBase; // Use with /:id
  static String get deleteFloor => blocksBase; // Use with /:blockId/floors/:floorId
  static String get toggleBlockActive => blocksBase; // Use with /:id/toggle-active
  static String get toggleUserActive => getAllUsers; // Use with /:id/toggle-active
  static String get updateUserStatus => getAllUsers; // Use with /:id/status
  static String get managersBase => '$authBase/managers';
  static String get updateManager => managersBase; // Use with /:id
  static String get deleteManager => managersBase; // Use with /:id
  static String get securityBase => '$authBase/security';
  static String get updateSecurity => securityBase; // Use with /:id
  static String get deleteSecurity => securityBase; // Use with /:id

  // Maintenance endpoints
  static String get maintenanceBase => '$baseUrl/maintenance';
  static String get getAllMaintenance => '$maintenanceBase/all';
  static String get getMaintenance => maintenanceBase;
  static String get setMaintenance => maintenanceBase;
  static String get updateMaintenance => maintenanceBase; // Use with /:id

  // Payment endpoints
  static String get paymentsBase => '$baseUrl/payments';
  static String get getAllPayments => paymentsBase;
  static String get getPaymentStats => '$paymentsBase/stats';
  static String get recordPayment => paymentsBase;

  // Notice endpoints
  static String get noticesBase => '$baseUrl/notices';
  static String get getAllNotices => noticesBase;
  static String get createNotice => noticesBase;
  static String get updateNotice => noticesBase; // Use with /:id
  static String get deleteNotice => noticesBase; // Use with /:id

  // Permission endpoints
  static String get permissionsBase => '$baseUrl/permissions';
  static String get getPermissions => permissionsBase; // Use with /:userType
  static String get updatePermissions => permissionsBase; // Use with /:userType

  // Ad endpoints
  static String get adsBase => '$baseUrl/ads';
  static String get getAds => adsBase;
  static String get createAd => adsBase;
  static String get deleteAd => adsBase; // Use with /:id

  // Health check
  static String get health => '$baseUrl/health';
}
