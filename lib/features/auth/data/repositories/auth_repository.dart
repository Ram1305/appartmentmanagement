import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  static const String _userKey = 'current_user';

  Future<UserModel?> getCurrentUser() async {
    try {
      // First try to get from API
      final response = await _apiService.getCurrentUser();
      if (response['success'] == true && response['user'] != null) {
        final user = UserModel.fromJson(response['user']);
        await saveCurrentUser(user);
        return user;
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      // Fallback to local storage on error
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson));
      }
      return null;
    }
  }

  Future<void> saveCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await _apiService.clearToken();
  }

  Future<UserModel?> login(
    String email,
    String password, [
    UserType? userType,
  ]) async {
    try {
      print('=== AUTH REPOSITORY LOGIN ===');
      print('Email: $email');
      print('UserType enum: $userType');
      print('UserType.name: ${userType?.name}');
      print('Sending to API service...');
      
      final response = await _apiService.login(
        email: email,
        password: password,
        userType: userType?.name,
      );

      print('=== API RESPONSE ===');
      print('Success: ${response['success']}');
      print('Error: ${response['error']}');
      print('User data: ${response['user']}');

      if (response['success'] == true && response['user'] != null) {
        final userData = response['user'];
        print('Parsing user data...');
        print('User userType from response: ${userData['userType']}');
        final user = UserModel.fromJson(userData);
        print('Parsed user userType: ${user.userType}');
        await saveCurrentUser(user);
        print('User saved successfully');
        return user;
      } else {
        print('Login failed: ${response['error']}');
        throw Exception(response['error'] ?? 'Login failed');
      }
    } catch (e) {
      print('=== LOGIN ERROR ===');
      print('Error: $e');
      throw Exception(e.toString());
    }
  }

  Future<UserModel> registerUser({
    required String name,
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
    String? secondaryMobileNumber,
    Gender? gender,
    UserType? userType,
    FamilyType? familyType,
    String? aadhaarCard,
    String? panCard,
    int? totalOccupants,
    String? block,
    String? floor,
    String? roomNumber,
    File? profilePic,
    File? aadhaarFront,
    File? aadhaarBack,
    File? panCardImage,
  }) async {
    try {
      final response = await _apiService.registerUser(
        name: name,
        username: username,
        email: email,
        password: password,
        mobileNumber: mobileNumber,
        secondaryMobileNumber: secondaryMobileNumber,
        gender: gender?.name,
        userType: userType?.name,
        familyType: familyType?.name,
        aadhaarCard: aadhaarCard,
        panCard: panCard,
        totalOccupants: totalOccupants,
        block: block,
        floor: floor,
        roomNumber: roomNumber,
        profilePic: profilePic,
        aadhaarFront: aadhaarFront,
        aadhaarBack: aadhaarBack,
        panCardImage: panCardImage,
      );

      if (response['success'] == true && response['user'] != null) {
        final userData = response['user'];
        final user = UserModel.fromJson(userData);
        await saveCurrentUser(user);
        return user;
      } else {
        throw Exception(response['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> sendOtp(String email) async {
    final response = await _apiService.sendOtp(email);
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Failed to send OTP');
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    final response = await _apiService.verifyOtp(email, otp);
    if (response['success'] != true || response['verified'] != true) {
      throw Exception(response['error'] ?? 'Invalid OTP');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await _apiService.forgotPassword(email);
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Failed to send OTP');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _apiService.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Failed to reset password');
    }
  }

  // Get all users from backend
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiService.getAllUsers();
      if (response['success'] == true && response['users'] != null) {
        final List<dynamic> usersList = response['users'];
        return usersList.map((userJson) => UserModel.fromJson(userJson)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveUser(UserModel user) async {
    // Save locally for now
    await saveCurrentUser(user);
  }
}
