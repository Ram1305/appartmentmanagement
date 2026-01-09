import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/models/visitor_model.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserDataEvent extends UserEvent {}

class AddVisitorEvent extends UserEvent {
  final String userId;
  final String name;
  final String mobileNumber;
  final VisitorCategory category;
  final RelativeType? relativeType;
  final VisitorType? type;
  final String reasonForVisit;
  final DateTime visitDateTime;
  final File? image;

  const AddVisitorEvent({
    required this.userId,
    required this.name,
    required this.mobileNumber,
    required this.category,
    this.relativeType,
    this.type,
    required this.reasonForVisit,
    required this.visitDateTime,
    this.image,
  });

  @override
  List<Object?> get props => [
        userId,
        name,
        mobileNumber,
        category,
        relativeType,
        type,
        reasonForVisit,
        visitDateTime,
        image,
      ];
}

class RaiseComplaintEvent extends UserEvent {
  final String userId;
  final ComplaintType type;
  final String description;

  const RaiseComplaintEvent({
    required this.userId,
    required this.type,
    required this.description,
  });

  @override
  List<Object?> get props => [userId, type, description];
}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<VisitorModel> visitors;
  final List<ComplaintModel> complaints;

  const UserLoaded({
    required this.visitors,
    required this.complaints,
  });

  @override
  List<Object?> get props => [visitors, complaints];
}

// BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  static const String _visitorsKey = 'visitors_list';
  static const String _complaintsKey = 'complaints_list';

  UserBloc() : super(UserInitial()) {
    on<LoadUserDataEvent>(_onLoadUserData);
    on<AddVisitorEvent>(_onAddVisitor);
    on<RaiseComplaintEvent>(_onRaiseComplaint);
  }

  Future<void> _onLoadUserData(
    LoadUserDataEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      var visitors = await _getVisitors();
      var complaints = await _getComplaints();
      
      // Initialize dummy visitor data if empty
      if (visitors.isEmpty) {
        final indianVisitorNames = [
          'Ramesh Kumar', 'Sunita Devi', 'Manoj Singh', 'Kiran Patel', 'Lakshmi Reddy',
          'Suresh Verma', 'Geeta Sharma', 'Rajesh Nair', 'Priya Iyer', 'Amit Joshi',
        ];
        
        final visitorTypes = VisitorType.values;
        
        for (int i = 0; i < indianVisitorNames.length && i < 10; i++) {
          final visitor = VisitorModel(
            id: const Uuid().v4(),
            name: indianVisitorNames[i],
            mobileNumber: '9${(1000000000 + i).toString().substring(1)}',
            category: VisitorCategory.outsider,
            type: visitorTypes[i % visitorTypes.length],
            block: ['A', 'B', 'C'][i % 3],
            homeNumber: '${(i % 10) + 1}',
            visitTime: DateTime.now().subtract(Duration(hours: i)),
          );
          visitors.add(visitor);
        }
        await _saveVisitors(visitors);
      }
      
      // Initialize dummy complaint data if empty
      if (complaints.isEmpty) {
        final complaintTypes = ComplaintType.values;
        final complaintDescriptions = [
          'Water leakage in bathroom',
          'Electrical socket not working',
          'Garbage not being collected',
          'Lift maintenance required',
          'Security issue at gate',
        ];
        
        for (int i = 0; i < 5; i++) {
          final complaint = ComplaintModel(
            id: const Uuid().v4(),
            userId: 'dummy_user_$i',
            userName: 'Rajesh Kumar',
            type: complaintTypes[i % complaintTypes.length],
            description: complaintDescriptions[i % complaintDescriptions.length],
            status: ComplaintStatus.pending,
            createdAt: DateTime.now().subtract(Duration(days: i)),
          );
          complaints.add(complaint);
        }
        await _saveComplaints(complaints);
      }
      
      emit(UserLoaded(visitors: visitors, complaints: complaints));
    } catch (e) {
      emit(UserLoaded(visitors: [], complaints: []));
    }
  }

  Future<void> _onAddVisitor(
    AddVisitorEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      final users = await _getUsers();
      final user = users.firstWhere(
        (u) => u.id == event.userId,
        orElse: () => UserModel(
          id: '',
          name: '',
          username: '',
          email: '',
          mobileNumber: '',
          userType: UserType.user,
          status: AccountStatus.pending,
        ),
      );
      final visitors = await _getVisitors();
      
      // Generate OTP
      final otp = _generateOTP();
      
      // Generate visitor ID for QR code
      final visitorId = const Uuid().v4();
      
      // Create QR code data (JSON string with visitor info)
      final qrData = jsonEncode({
        'visitorId': visitorId,
        'name': event.name,
        'mobileNumber': event.mobileNumber,
        'block': user.block ?? 'A',
        'homeNumber': user.roomNumber ?? '101',
        'visitTime': event.visitDateTime.toIso8601String(),
        'otp': otp,
      });
      
      // Handle image upload (for now, store path - in production, upload to server)
      String? imagePath;
      if (event.image != null) {
        // In production, upload image to server and get URL
        // For now, store local path
        imagePath = event.image!.path;
      }
      
      final newVisitor = VisitorModel(
        id: visitorId,
        name: event.name,
        mobileNumber: event.mobileNumber,
        category: event.category,
        relativeType: event.relativeType,
        type: event.category == VisitorCategory.relative
            ? VisitorType.guest // Default for relatives
            : (event.type ?? VisitorType.other),
        reasonForVisit: event.reasonForVisit,
        image: imagePath,
        block: user.block ?? 'A',
        homeNumber: user.roomNumber ?? '101',
        visitTime: event.visitDateTime,
        otp: otp,
        qrCode: qrData,
      );
      
      visitors.add(newVisitor);
      await _saveVisitors(visitors);
      final complaints = await _getComplaints();
      emit(UserLoaded(visitors: visitors, complaints: complaints));
      
      // Navigate to visitor details page (handled in UI)
    } catch (e) {
      // Handle error
    }
  }

  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _onRaiseComplaint(
    RaiseComplaintEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      final complaints = await _getComplaints();
      final users = await _getUsers();
      final user = users.firstWhere(
        (u) => u.id == event.userId,
        orElse: () => UserModel(
          id: '',
          name: 'Unknown',
          username: 'unknown',
          email: '',
          mobileNumber: '',
          userType: UserType.user,
          status: AccountStatus.pending,
        ),
      );
      final newComplaint = ComplaintModel(
        id: const Uuid().v4(),
        userId: event.userId,
        userName: user.name,
        type: event.type,
        description: event.description,
        status: ComplaintStatus.pending,
        createdAt: DateTime.now(),
      );
      complaints.add(newComplaint);
      await _saveComplaints(complaints);
      final visitors = await _getVisitors();
      emit(UserLoaded(visitors: visitors, complaints: complaints));
    } catch (e) {
      // Handle error
    }
  }

  Future<List<VisitorModel>> _getVisitors() async {
    final prefs = await SharedPreferences.getInstance();
    final visitorsJson = prefs.getString(_visitorsKey);
    if (visitorsJson != null) {
      final List<dynamic> visitorsList = jsonDecode(visitorsJson);
      return visitorsList.map((v) => VisitorModel.fromJson(v)).toList();
    }
    return [];
  }

  Future<void> _saveVisitors(List<VisitorModel> visitors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _visitorsKey,
      jsonEncode(visitors.map((v) => v.toJson()).toList()),
    );
  }

  Future<List<ComplaintModel>> _getComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final complaintsJson = prefs.getString(_complaintsKey);
    if (complaintsJson != null) {
      final List<dynamic> complaintsList = jsonDecode(complaintsJson);
      return complaintsList
          .map((c) => ComplaintModel.fromJson(c))
          .toList();
    }
    return [];
  }

  Future<void> _saveComplaints(List<ComplaintModel> complaints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _complaintsKey,
      jsonEncode(complaints.map((c) => c.toJson()).toList()),
    );
  }

  Future<List<UserModel>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users_list');
    if (usersJson != null) {
      final List<dynamic> usersList = jsonDecode(usersJson);
      return usersList.map((u) => UserModel.fromJson(u)).toList();
    }
    return [];
  }
}

