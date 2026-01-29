import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Production server URL (used in release builds).
  static const String _productionBaseUrl = 'http://72.61.236.154:5000/api';

  /// Local/debug server URL (used in debug builds).
  /// - Android emulator: use 10.0.2.2
  /// - Physical device: use your PC's IP (e.g. 192.168.1.100) so phone and PC are on same Wi-Fi
  static const String _debugBaseUrl = 'http://72.61.236.154:5000/api';

  /// Override at runtime: run with
  ///   flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:5000/api
  /// when using a physical device (replace YOUR_PC_IP with your computer's IP, e.g. 192.168.29.61).
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Base URL: override if set, else debug URL in debug mode, else production.
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    return kDebugMode ? _debugBaseUrl : _productionBaseUrl;
  }

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

  // Razorpay (front-end key for checkout)
  static const String razorpayKey = 'rzp_test_S8OG5QwdE7JwGw';

  // Payment endpoints
  static String get paymentsBase => '$baseUrl/payments';
  static String get getAllPayments => paymentsBase;
  static String get getPaymentStats => '$paymentsBase/stats';
  static String get getMyPayments => '$paymentsBase/my';
  static String get recordPayment => paymentsBase;
  static String get assignPayment => paymentsBase;
  static String get createRazorpayOrder => '$paymentsBase/create-order';
  static String getPaymentByIdUrl(String id) => '$paymentsBase/$id';
  static String completePaymentUrl(String id) => '$paymentsBase/$id/complete';

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

  // Amenity endpoints
  static String get amenitiesBase => '$baseUrl/amenities';
  static String get getAmenities => amenitiesBase;
  static String get createAmenity => amenitiesBase;
  static String updateAmenityUrl(String id) => '$amenitiesBase/$id';
  static String deleteAmenityUrl(String id) => '$amenitiesBase/$id';

  // Vehicle endpoints
  static String get vehiclesBase => '$baseUrl/vehicles';
  static String get getVehicles => vehiclesBase;
  static String get addVehicle => vehiclesBase;
  static String deleteVehicleUrl(String id) => '$vehiclesBase/$id';

  // Family member endpoints
  static String get familyMembersBase => '$baseUrl/family-members';
  static String get getFamilyMembers => familyMembersBase;
  static String get addFamilyMember => familyMembersBase;
  static String deleteFamilyMemberUrl(String id) => '$familyMembersBase/$id';

  // Visitor endpoints (security: all visitors / today)
  static String get visitorsBase => '$baseUrl/visitors';
  static String get getSecurityVisitors => '$visitorsBase/all/list';
  static String get createSecurityVisitor => '$visitorsBase/security';
  static String get getVisitorsForMyUnit => '$visitorsBase/my-unit';
  static String visitorApprovalUrl(String visitorId) => '$visitorsBase/$visitorId/approval';

  // Security list for residents
  static String get getSecurityList => '$securityBase/list';

  // Support / Help desk endpoints
  static String get supportTicketsBase => '$baseUrl/support/tickets';
  static String supportTicketById(String id) => '$supportTicketsBase/$id';
  static String supportMessages(String ticketId) => '$supportTicketsBase/$ticketId/messages';
  static String supportSendMessage(String ticketId) => '$supportTicketsBase/$ticketId/messages';
  static String supportTicketStatus(String id) => '$supportTicketsBase/$id/status';

  // Complaints endpoints
  static String get complaintsBase => '$baseUrl/complaints';
  static String complaintStatus(String id) => '$complaintsBase/$id/status';

  // Kid exit endpoints (user–security communication)
  static String get kidExitsBase => '$baseUrl/kid-exits';
  static String get reportKidExit => kidExitsBase;
  static String get getKidExits => kidExitsBase;
  static String kidExitAcknowledgeUrl(String id) => '$kidExitsBase/$id/acknowledge';

  // Subscription endpoints (admin subscription, app-active for user/security)
  static String get subscriptionBase => '$baseUrl/subscription';
  static String get subscriptionPlans => '$subscriptionBase/plans';
  static String get subscriptionPlansHistory => '$subscriptionBase/plans/history';
  static String get subscriptionCreateOrder => '$subscriptionBase/create-order';
  static String get subscriptionVerify => '$subscriptionBase/verify';
  static String get subscriptionMy => '$subscriptionBase/my';
  static String get subscriptionAppActive => '$subscriptionBase/app-active';

  // Health check
  static String get health => '$baseUrl/health';
}
