import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/services/api_service.dart';

// Events
abstract class ManagerEvent extends Equatable {
  const ManagerEvent();

  @override
  List<Object?> get props => [];
}

class LoadManagerDataEvent extends ManagerEvent {}

class UpdateUserStatusEvent extends ManagerEvent {
  final String userId;
  final AccountStatus status;
  final String? block;
  final String? floor;
  final String? roomNumber;

  const UpdateUserStatusEvent({
    required this.userId,
    required this.status,
    this.block,
    this.floor,
    this.roomNumber,
  });

  @override
  List<Object?> get props => [userId, status, block, floor, roomNumber];
}

class UpdateComplaintStatusEvent extends ManagerEvent {
  final String complaintId;
  final ComplaintStatus status;

  const UpdateComplaintStatusEvent({
    required this.complaintId,
    required this.status,
  });

  @override
  List<Object?> get props => [complaintId, status];
}

// States
abstract class ManagerState extends Equatable {
  const ManagerState();

  @override
  List<Object?> get props => [];
}

class ManagerInitial extends ManagerState {}

class ManagerLoading extends ManagerState {}

class ManagerLoaded extends ManagerState {
  final List<UserModel> users;
  final List<ComplaintModel> complaints;

  const ManagerLoaded({
    required this.users,
    required this.complaints,
  });

  @override
  List<Object?> get props => [users, complaints];
}

// BLoC
class ManagerBloc extends Bloc<ManagerEvent, ManagerState> {
  final ApiService _apiService = ApiService();

  ManagerBloc() : super(ManagerInitial()) {
    on<LoadManagerDataEvent>(_onLoadManagerData);
    on<UpdateUserStatusEvent>(_onUpdateUserStatus);
    on<UpdateComplaintStatusEvent>(_onUpdateComplaintStatus);
  }

  Future<void> _onLoadManagerData(
    LoadManagerDataEvent event,
    Emitter<ManagerState> emit,
  ) async {
    emit(ManagerLoading());
    try {
      // Fetch users from API
      final usersResponse = await _apiService.getAllUsers();
      List<UserModel> users = [];
      
      if (usersResponse['success'] == true && usersResponse['users'] != null) {
        final List<dynamic> usersList = usersResponse['users'];
        users = usersList.map((u) => UserModel.fromJson(u)).toList();
      }
      
      // For now, complaints are empty - can be added when complaint API is available
      // TODO: Add complaint API endpoint and fetch from backend
      List<ComplaintModel> complaints = [];
      
      emit(ManagerLoaded(users: users, complaints: complaints));
    } catch (e) {
      print('Error loading manager data: $e');
      emit(ManagerLoaded(users: [], complaints: []));
    }
  }

  Future<void> _onUpdateUserStatus(
    UpdateUserStatusEvent event,
    Emitter<ManagerState> emit,
  ) async {
    try {
      // Update user status via API
      final response = await _apiService.updateUserStatus(
        event.userId,
        event.status.name,
        block: event.block,
        floor: event.floor,
        roomNumber: event.roomNumber,
      );
      
      if (response['success'] == true) {
        // Reload data from API
        add(LoadManagerDataEvent());
      } else {
        print('Failed to update user status: ${response['error']}');
        // Reload data anyway to refresh state
        add(LoadManagerDataEvent());
      }
    } catch (e) {
      print('Error updating user status: $e');
      // Reload data anyway to refresh state
      add(LoadManagerDataEvent());
    }
  }

  Future<void> _onUpdateComplaintStatus(
    UpdateComplaintStatusEvent event,
    Emitter<ManagerState> emit,
  ) async {
    try {
      // TODO: Add complaint status update API endpoint
      // For now, just reload data
      final currentState = state;
      if (currentState is ManagerLoaded) {
        final updatedComplaints = currentState.complaints.map((c) {
          if (c.id == event.complaintId) {
            return ComplaintModel(
              id: c.id,
              userId: c.userId,
              userName: c.userName,
              type: c.type,
              description: c.description,
              status: event.status,
              createdAt: c.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return c;
        }).toList();
        
        emit(ManagerLoaded(
          users: currentState.users,
          complaints: updatedComplaints,
        ));
      }
    } catch (e) {
      print('Error updating complaint status: $e');
    }
  }
}

