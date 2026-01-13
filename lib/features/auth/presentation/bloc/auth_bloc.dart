import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  final UserType? userType;

  const LoginEvent({
    required this.email,
    required this.password,
    this.userType,
  });

  @override
  List<Object?> get props => [email, password, userType];
}

class RegisterUserEvent extends AuthEvent {
  final String name;
  final String username;
  final String email;
  final String password;
  final String mobileNumber;
  final String? secondaryMobileNumber;
  final Gender? gender;
  final UserType? userType;
  final FamilyType? familyType;
  final String? aadhaarCard;
  final String? panCard;
  final int? totalOccupants;
  final String? block;
  final String? floor;
  final String? roomNumber;
  final String? profilePicPath;
  final String? aadhaarFrontPath;
  final String? aadhaarBackPath;
  final String? panCardImagePath;

  const RegisterUserEvent({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.mobileNumber,
    this.secondaryMobileNumber,
    this.gender,
    this.userType,
    this.familyType,
    this.aadhaarCard,
    this.panCard,
    this.totalOccupants,
    this.block,
    this.floor,
    this.roomNumber,
    this.profilePicPath,
    this.aadhaarFrontPath,
    this.aadhaarBackPath,
    this.panCardImagePath,
  });

  @override
  List<Object?> get props => [
        name,
        username,
        email,
        password,
        mobileNumber,
        secondaryMobileNumber,
        gender,
        userType,
        familyType,
        aadhaarCard,
        panCard,
        totalOccupants,
        block,
        floor,
        roomNumber,
        profilePicPath,
        aadhaarFrontPath,
        aadhaarBackPath,
        panCardImagePath,
      ];
}

class SendOtpEvent extends AuthEvent {
  final String email;
  final bool isForgotPassword;

  const SendOtpEvent({
    required this.email,
    this.isForgotPassword = false,
  });

  @override
  List<Object?> get props => [email, isForgotPassword];
}

class VerifyOtpEvent extends AuthEvent {
  final String email;
  final String otp;

  const VerifyOtpEvent({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

class ResetPasswordEvent extends AuthEvent {
  final String email;
  final String otp;
  final String newPassword;

  const ResetPasswordEvent({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, otp, newPassword];
}

class LogoutEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class OtpSent extends AuthState {
  final String email;

  const OtpSent({required this.email});

  @override
  List<Object?> get props => [email];
}

class OtpVerified extends AuthState {
  final String email;

  const OtpVerified({required this.email});

  @override
  List<Object?> get props => [email];
}

class PasswordResetSuccess extends AuthState {
  const PasswordResetSuccess();
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<RegisterUserEvent>(_onRegisterUser);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResetPasswordEvent>(_onResetPassword);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final user = await authRepository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('=== AUTH BLOC LOGIN ===');
    debugPrint('Email: ${event.email}');
    debugPrint('UserType: ${event.userType}');
    debugPrint('UserType.name: ${event.userType?.name}');

    emit(AuthLoading());
    try {
      debugPrint('Calling authRepository.login...');
      final user = await authRepository.login(
        event.email,
        event.password,
        event.userType,
      );
      debugPrint('AuthRepository returned user: ${user != null}');
      if (user != null) {
        debugPrint('User details:');
        debugPrint('  - Name: ${user.name}');
        debugPrint('  - Email: ${user.email}');
        debugPrint('  - UserType: ${user.userType}');
        debugPrint('  - Status: ${user.status}');
        debugPrint('  - IsActive: ${user.isActive}');
        emit(AuthAuthenticated(user: user));
      } else {
        debugPrint('User is null, emitting error');
        emit(const AuthError(message: 'Invalid email or password'));
      }
    } catch (e) {
      debugPrint('=== AUTH BLOC ERROR ===');
      debugPrint('Error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterUser(
    RegisterUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.registerUser(
        name: event.name,
        username: event.username,
        email: event.email,
        password: event.password,
        mobileNumber: event.mobileNumber,
        secondaryMobileNumber: event.secondaryMobileNumber,
        gender: event.gender,
        userType: event.userType,
        familyType: event.familyType,
        aadhaarCard: event.aadhaarCard,
        panCard: event.panCard,
        totalOccupants: event.totalOccupants,
        block: event.block,
        floor: event.floor,
        roomNumber: event.roomNumber,
        profilePic: event.profilePicPath != null
            ? await _getFileFromPath(event.profilePicPath!)
            : null,
        aadhaarFront: event.aadhaarFrontPath != null
            ? await _getFileFromPath(event.aadhaarFrontPath!)
            : null,
        aadhaarBack: event.aadhaarBackPath != null
            ? await _getFileFromPath(event.aadhaarBackPath!)
            : null,
        panCardImage: event.panCardImagePath != null
            ? await _getFileFromPath(event.panCardImagePath!)
            : null,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<File?> _getFileFromPath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _onSendOtp(
    SendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      if (event.isForgotPassword) {
        await authRepository.forgotPassword(event.email);
      } else {
        await authRepository.sendOtp(event.email);
      }
      emit(OtpSent(email: event.email));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.verifyOtp(event.email, event.otp);
      emit(OtpVerified(email: event.email));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.resetPassword(
        email: event.email,
        otp: event.otp,
        newPassword: event.newPassword,
      );
      emit(const PasswordResetSuccess());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
