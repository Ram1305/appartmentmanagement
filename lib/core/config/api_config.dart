class ApiConfig {
  // Update this to your backend URL
  // For Android emulator, use: 'http://10.0.2.2:5000/api'
  // For iOS simulator, use: 'http://localhost:5000/api'
  // For physical device, use your computer's IP: 'http://192.168.x.x:5000/api'
  static const String baseUrl = 'http://72.61.236.154:5000/api'; // Production HTTPS server
  
  static const String authBase = '$baseUrl/auth';
  
  // Auth endpoints
  static const String register = '$authBase/register';
  static const String registerAdmin = '$authBase/register-admin';
  static const String login = '$authBase/login';
  static const String sendOtp = '$authBase/send-otp';
  static const String verifyOtp = '$authBase/verify-otp';
  static const String forgotPassword = '$authBase/forgot-password';
  static const String resetPassword = '$authBase/reset-password';
  static const String getCurrentUser = '$authBase/me';
  static const String getAllUsers = '$authBase/users';
  
  // Block endpoints
  static const String blocksBase = '$baseUrl/blocks';
  static const String getAllBlocks = blocksBase;
  static const String getBlock = blocksBase; // Use with /:id
  static const String createBlock = blocksBase;
  static const String addFloor = blocksBase; // Use with /:id/floors
  static const String addRoom = blocksBase; // Use with /:blockId/floors/:floorId/rooms
  static const String updateBlock = blocksBase; // Use with /:id
  static const String updateFloor = blocksBase; // Use with /:blockId/floors/:floorId
  static const String deleteBlock = blocksBase; // Use with /:id
  static const String deleteFloor = blocksBase; // Use with /:blockId/floors/:floorId
  static const String toggleBlockActive = blocksBase; // Use with /:id/toggle-active
  static const String toggleUserActive = getAllUsers; // Use with /:id/toggle-active
  static const String updateUserStatus = getAllUsers; // Use with /:id/status
  static const String managersBase = '$authBase/managers';
  static const String updateManager = managersBase; // Use with /:id
  static const String deleteManager = managersBase; // Use with /:id
  static const String securityBase = '$authBase/security';
  static const String updateSecurity = securityBase; // Use with /:id
  static const String deleteSecurity = securityBase; // Use with /:id
  
  // Maintenance endpoints
  static const String maintenanceBase = '$baseUrl/maintenance';
  static const String getAllMaintenance = '$maintenanceBase/all';
  static const String getMaintenance = maintenanceBase;
  static const String setMaintenance = maintenanceBase;
  static const String updateMaintenance = maintenanceBase; // Use with /:id
  
  // Payment endpoints
  static const String paymentsBase = '$baseUrl/payments';
  static const String getAllPayments = paymentsBase;
  static const String getPaymentStats = '$paymentsBase/stats';
  static const String recordPayment = paymentsBase;
  
  // Notice endpoints
  static const String noticesBase = '$baseUrl/notices';
  static const String getAllNotices = noticesBase;
  static const String createNotice = noticesBase;
  static const String updateNotice = noticesBase; // Use with /:id
  static const String deleteNotice = noticesBase; // Use with /:id
  
  // Permission endpoints
  static const String permissionsBase = '$baseUrl/permissions';
  static const String getPermissions = permissionsBase; // Use with /:userType
  static const String updatePermissions = permissionsBase; // Use with /:userType

  // Ad endpoints
  static const String adsBase = '$baseUrl/ads';
  static const String getAds = adsBase;
  static const String createAd = adsBase;
  static const String deleteAd = adsBase; // Use with /:id
  
  // Health check
  static const String health = '$baseUrl/health';
}
