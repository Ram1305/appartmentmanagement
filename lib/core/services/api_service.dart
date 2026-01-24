import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout:
            const Duration(seconds: 60), // Increased from 30 to 60 seconds
        receiveTimeout:
            const Duration(seconds: 60), // Increased from 30 to 60 seconds
        sendTimeout: const Duration(seconds: 60), // Added send timeout
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptor to include token in requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired or invalid
            clearToken();
          }

          // Handle connection timeout errors - modify error message
          String? customMessage;
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            customMessage =
                'Connection timeout. Please check your internet connection and ensure the server is running.';
          } else if (error.type == DioExceptionType.connectionError) {
            customMessage =
                'Unable to connect to server. Please check your internet connection and verify the server is running at ${ApiConfig.baseUrl}';
          }

          if (customMessage != null) {
            // Create a new error with custom message
            final customError = DioException(
              requestOptions: error.requestOptions,
              type: error.type,
              error: customMessage,
              response: error.response,
            );
            handler.next(customError);
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Register user with images
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
    String? secondaryMobileNumber,
    String? gender,
    String? userType,
    String? familyType,
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
      final formData = FormData.fromMap({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'mobileNumber': mobileNumber,
        if (secondaryMobileNumber != null && secondaryMobileNumber.isNotEmpty)
          'secondaryMobileNumber': secondaryMobileNumber,
        if (gender != null) 'gender': gender,
        if (userType != null) 'userType': userType,
        if (familyType != null) 'familyType': familyType,
        if (aadhaarCard != null && aadhaarCard.isNotEmpty)
          'aadhaarCard': aadhaarCard,
        if (panCard != null && panCard.isNotEmpty) 'panCard': panCard,
        if (totalOccupants != null) 'totalOccupants': totalOccupants.toString(),
        if (block != null && block.isNotEmpty) 'block': block,
        if (floor != null && floor.isNotEmpty) 'floor': floor,
        if (roomNumber != null && roomNumber.isNotEmpty)
          'roomNumber': roomNumber,
        if (profilePic != null)
          'profilePic': await MultipartFile.fromFile(
            profilePic.path,
            filename: 'profilePic.jpg',
          ),
        if (aadhaarFront != null)
          'aadhaarFront': await MultipartFile.fromFile(
            aadhaarFront.path,
            filename: 'aadhaarFront.jpg',
          ),
        if (aadhaarBack != null)
          'aadhaarBack': await MultipartFile.fromFile(
            aadhaarBack.path,
            filename: 'aadhaarBack.jpg',
          ),
        if (panCardImage != null)
          'panCard': await MultipartFile.fromFile(
            panCardImage.path,
            filename: 'panCard.jpg',
          ),
      });

      final response = await _dio.post(
        ApiConfig.register,
        data: formData,
      );

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {
          'success': true,
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Registration failed',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? userType,
  }) async {
    try {
      debugPrint('=== API SERVICE LOGIN ===');
      debugPrint('URL: ${ApiConfig.login}');
      debugPrint('Email: $email');
      debugPrint('Password: ${password.isNotEmpty ? "***" : "empty"}');
      debugPrint('UserType: $userType');

      final requestData = {
        'email': email,
        'password': password,
        if (userType != null) 'userType': userType,
      };
      debugPrint('Request data: $requestData');

      final response = await _dio.post(
        ApiConfig.login,
        data: requestData,
      );

      debugPrint('=== API RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['token'] != null) {
          await saveToken(data['token']);
          debugPrint('Token saved successfully');
        }
        return {
          'success': true,
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        debugPrint('Non-200 status code: ${response.statusCode}');
        return {
          'success': false,
          'error': response.data['error'] ?? 'Login failed',
        };
      }
    } on DioException catch (e) {
      debugPrint('=== DIO EXCEPTION ===');
      debugPrint('Error type: ${e.type}');
      debugPrint('Error message: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');

      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      debugPrint('Final error message: $errorMessage');

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      debugPrint('=== GENERAL EXCEPTION ===');
      debugPrint('Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _dio.post(
        ApiConfig.sendOtp,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to send OTP',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post(
        ApiConfig.verifyOtp,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'verified': response.data['verified'] ?? false,
          'message': response.data['message'] ?? 'OTP verified successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Invalid OTP',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to send OTP',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to reset password',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Register admin
  Future<Map<String, dynamic>> registerAdmin({
    required String name,
    required String username,
    required String email,
    required String password,
    required String mobileNumber,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.registerAdmin,
        data: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'mobileNumber': mobileNumber,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {
          'success': true,
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Registration failed',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConfig.getCurrentUser);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': response.data['user'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get user',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get all users
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get(ApiConfig.getAllUsers);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'users': response.data['users'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get users',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get all blocks
  Future<Map<String, dynamic>> getAllBlocks() async {
    try {
      final response = await _dio.get(ApiConfig.getAllBlocks);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'blocks': response.data['blocks'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get blocks',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create block
  Future<Map<String, dynamic>> createBlock(String name) async {
    try {
      final response = await _dio.post(
        ApiConfig.createBlock,
        data: {'name': name},
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'block': response.data['block'],
          'message': response.data['message'] ?? 'Block created successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to create block',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Add floor to block
  Future<Map<String, dynamic>> addFloor({
    required String blockId,
    required String floorNumber,
    required List<Map<String, dynamic>>
        roomConfigurations, // [{type: '1BHK', count: 4}, {type: '2BHK', count: 2}]
    String? roomNumber, // Optional specific room number for single room
  }) async {
    try {
      // Generate rooms based on configurations
      final rooms = <Map<String, dynamic>>[];
      int roomIndex = 1;

      for (final config in roomConfigurations) {
        final roomType = config['type'] as String;
        final roomCount = config['count'] as int;

        for (int i = 0; i < roomCount; i++) {
          // Use provided room number if available and it's the first room, otherwise auto-generate
          final number = (roomNumber != null &&
                  roomNumber.isNotEmpty &&
                  i == 0 &&
                  roomCount == 1)
              ? roomNumber
              : '$floorNumber${roomIndex.toString().padLeft(2, '0')}';
          rooms.add({
            'number': number,
            'type': roomType,
          });
          roomIndex++;
        }
      }

      final response = await _dio.post(
        '${ApiConfig.addFloor}/$blockId/floors',
        data: {
          'number': floorNumber,
          'rooms': rooms,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'block': response.data['block'],
          'message': response.data['message'] ?? 'Floor added successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to add floor',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Add room to floor
  Future<Map<String, dynamic>> addRoom({
    required String blockId,
    required String floorId,
    required String roomNumber,
    required String roomType,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.addRoom}/$blockId/floors/$floorId/rooms',
        data: {
          'number': roomNumber,
          'type': roomType,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'block': response.data['block'],
          'message': response.data['message'] ?? 'Room added successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to add room',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Toggle user active status
  Future<Map<String, dynamic>> toggleUserActive(String userId) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.getAllUsers}/$userId/toggle-active',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'User status updated',
          'user': response.data['user'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to update user status',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update block
  Future<Map<String, dynamic>> updateBlock(String blockId, String name) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.updateBlock}/$blockId',
        data: {'name': name},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Block updated successfully',
          'block': response.data['block'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to update block',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Delete block
  Future<Map<String, dynamic>> deleteBlock(String blockId) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.deleteBlock}/$blockId',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Block deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to delete block',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update floor
  Future<Map<String, dynamic>> updateFloor({
    required String blockId,
    required String floorId,
    required String floorNumber,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.updateFloor}/$blockId/floors/$floorId',
        data: {'number': floorNumber},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Floor updated successfully',
          'block': response.data['block'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to update floor',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Delete floor
  Future<Map<String, dynamic>> deleteFloor({
    required String blockId,
    required String floorId,
  }) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.deleteFloor}/$blockId/floors/$floorId',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Floor deleted successfully',
          'block': response.data['block'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to delete floor',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Toggle block active status
  Future<Map<String, dynamic>> toggleBlockActive(String blockId) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.toggleBlockActive}/$blockId/toggle-active',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Block status updated',
          'block': response.data['block'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to update block status',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get all maintenance records
  Future<Map<String, dynamic>> getAllMaintenance() async {
    try {
      final response = await _dio.get(ApiConfig.getAllMaintenance);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'maintenance': response.data['maintenance'] ?? [],
          'count': response.data['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get maintenance list',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get maintenance amount
  Future<Map<String, dynamic>> getMaintenance() async {
    try {
      final response = await _dio.get(ApiConfig.getMaintenance);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'maintenance': response.data['maintenance'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get maintenance',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Set maintenance amount
  Future<Map<String, dynamic>> setMaintenance({
    required double amount,
    String? month,
    int? year,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.setMaintenance,
        data: {
          'amount': amount,
          'month': month,
          'year': year,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Maintenance amount set successfully',
          'maintenance': response.data['maintenance'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to set maintenance',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update user status (approve/reject)
  Future<Map<String, dynamic>> updateUserStatus(
    String userId,
    String status, {
    String? block,
    String? floor,
    String? roomNumber,
  }) async {
    try {
      final data = {'status': status};
      if (block != null) data['block'] = block;
      if (floor != null) data['floor'] = floor;
      if (roomNumber != null) data['roomNumber'] = roomNumber;

      final response = await _dio.put(
        '${ApiConfig.updateUserStatus}/$userId/status',
        data: data,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'User status updated',
          'user': response.data['user'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to update user status',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get all payments
  Future<Map<String, dynamic>> getAllPayments(
      {String? month, int? year, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        ApiConfig.getAllPayments,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'payments': response.data['payments'],
          'count': response.data['count'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get payments',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getPaymentStats(
      {String? month, int? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await _dio.get(
        ApiConfig.getPaymentStats,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'stats': response.data['stats'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get payment stats',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get all notices
  Future<Map<String, dynamic>> getAllNotices({
    String? type,
    String? targetAudience,
    bool? isActive,
  }) async {
    // Get all events (notices with type='event')
    if (type == 'event') {
      type = 'event';
    }
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (targetAudience != null) {
        queryParams['targetAudience'] = targetAudience;
      }
      if (isActive != null) queryParams['isActive'] = isActive.toString();

      final response = await _dio.get(
        ApiConfig.getAllNotices,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'notices': response.data['notices'],
          'count': response.data['count'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get notices',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create notice
  Future<Map<String, dynamic>> createNotice({
    required String title,
    required String content,
    String? subtitle,
    String? type,
    String? targetAudience,
    String? priority,
    String? expiryDate,
    String? eventDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.createNotice,
        data: {
          'title': title,
          'subtitle': subtitle,
          'content': content,
          'type': type,
          'targetAudience': targetAudience,
          'priority': priority,
          'expiryDate': expiryDate,
          'eventDate': eventDate,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Notice created successfully',
          'notice': response.data['notice'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to create notice',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update notice
  Future<Map<String, dynamic>> updateNotice(
      String noticeId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.updateNotice}/$noticeId',
        data: data,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Notice updated successfully',
          'notice': response.data['notice'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to update notice',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Delete notice
  Future<Map<String, dynamic>> deleteNotice(String noticeId) async {
    try {
      final response = await _dio.delete('${ApiConfig.deleteNotice}/$noticeId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Notice deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to delete notice',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get ads
  Future<Map<String, dynamic>> getAds() async {
    try {
      final response = await _dio.get(ApiConfig.getAds);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'ads': response.data['ads'] ?? [],
          'count': response.data['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get ads',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create ad
  Future<Map<String, dynamic>> createAd(File image, {int? displayOrder}) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: 'ad_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        if (displayOrder != null) 'displayOrder': displayOrder.toString(),
      });

      final response = await _dio.post(
        ApiConfig.createAd,
        data: formData,
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Ad created successfully',
          'ad': response.data['ad'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to create ad',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Delete ad
  Future<Map<String, dynamic>> deleteAd(String adId) async {
    try {
      final response = await _dio.delete('${ApiConfig.deleteAd}/$adId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Ad deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to delete ad',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get permissions
  Future<Map<String, dynamic>> getPermissions(String userType) async {
    try {
      final response = await _dio.get('${ApiConfig.getPermissions}/$userType');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'permission': response.data['permission'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to get permissions',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update permissions
  Future<Map<String, dynamic>> updatePermissions(
    String userType,
    Map<String, bool> permissions,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.updatePermissions}/$userType',
        data: {'permissions': permissions},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Permissions updated successfully',
          'permission': response.data['permission'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to update permissions',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the server is running.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection and verify the server is running.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update manager
  Future<Map<String, dynamic>> updateManager({
    required String managerId,
    String? name,
    String? email,
    String? mobileNumber,
    String? password,
    File? profilePic,
    File? idProof,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (mobileNumber != null && mobileNumber.isNotEmpty)
          'mobileNumber': mobileNumber,
        if (password != null && password.isNotEmpty) 'password': password,
        if (profilePic != null)
          'profilePic': await MultipartFile.fromFile(
            profilePic.path,
            filename: 'profilePic.jpg',
          ),
        if (idProof != null)
          'aadhaarFront': await MultipartFile.fromFile(
            idProof.path,
            filename: 'idProof.jpg',
          ),
      });

      final response = await _dio.put(
        '${ApiConfig.updateManager}/$managerId',
        data: formData,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'manager': response.data['manager'],
          'message': response.data['message'] ?? 'Manager updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Update failed',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to connect to server.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Delete manager
  Future<Map<String, dynamic>> deleteManager(String managerId) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.deleteManager}/$managerId',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Manager deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Delete failed',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to connect to server.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update security staff
  Future<Map<String, dynamic>> updateSecurity({
    required String securityId,
    String? name,
    String? email,
    String? mobileNumber,
    String? password,
    File? profilePic,
    File? idProof,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (mobileNumber != null && mobileNumber.isNotEmpty)
          'mobileNumber': mobileNumber,
        if (password != null && password.isNotEmpty) 'password': password,
        if (profilePic != null)
          'profilePic': await MultipartFile.fromFile(
            profilePic.path,
            filename: 'profilePic.jpg',
          ),
        if (idProof != null)
          'aadhaarFront': await MultipartFile.fromFile(
            idProof.path,
            filename: 'idProof.jpg',
          ),
      });

      final response = await _dio.put(
        '${ApiConfig.updateSecurity}/$securityId',
        data: formData,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'security': response.data['security'],
          'message':
              response.data['message'] ?? 'Security staff updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Update failed',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to connect to server.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Delete security staff
  Future<Map<String, dynamic>> deleteSecurity(String securityId) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.deleteSecurity}/$securityId',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Security staff deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Delete failed',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to connect to server.';
      } else if (e.response != null) {
        errorMessage =
            e.response?.data['error'] ?? e.message ?? 'Network error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
