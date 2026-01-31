import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../../core/models/block_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/auth/data/repositories/auth_repository.dart';
import '../../../../core/services/api_service.dart';
import 'package:flutter/foundation.dart';

// Events
abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadBlocksEvent extends AdminEvent {}

class CreateBlockEvent extends AdminEvent {
  final String blockName;
  final int? numberOfFloors;

  const CreateBlockEvent({
    required this.blockName,
    this.numberOfFloors,
  });

  @override
  List<Object?> get props => [blockName, numberOfFloors];
}

class AddFloorEvent extends AdminEvent {
  final String blockId;
  final String floorNumber;
  final List<Map<String, dynamic>>
      roomConfigurations; // [{type: '1BHK', count: 4}, {type: '2BHK', count: 2}]
  final String? roomNumber; // Optional specific room number for single room

  const AddFloorEvent({
    required this.blockId,
    required this.floorNumber,
    required this.roomConfigurations,
    this.roomNumber,
  });

  @override
  List<Object?> get props =>
      [blockId, floorNumber, roomConfigurations, roomNumber];
}

class AddRoomEvent extends AdminEvent {
  final String blockId;
  final String floorId;
  final String roomNumber;
  final String roomType;

  const AddRoomEvent({
    required this.blockId,
    required this.floorId,
    required this.roomNumber,
    required this.roomType,
  });

  @override
  List<Object?> get props => [blockId, floorId, roomNumber, roomType];
}

class EditBlockEvent extends AdminEvent {
  final String blockId;
  final String name;

  const EditBlockEvent({
    required this.blockId,
    required this.name,
  });

  @override
  List<Object?> get props => [blockId, name];
}

class DeleteBlockEvent extends AdminEvent {
  final String blockId;

  const DeleteBlockEvent(this.blockId);

  @override
  List<Object?> get props => [blockId];
}

class EditFloorEvent extends AdminEvent {
  final String blockId;
  final String floorId;
  final String floorNumber;

  const EditFloorEvent({
    required this.blockId,
    required this.floorId,
    required this.floorNumber,
  });

  @override
  List<Object?> get props => [blockId, floorId, floorNumber];
}

class DeleteFloorEvent extends AdminEvent {
  final String blockId;
  final String floorId;

  const DeleteFloorEvent({
    required this.blockId,
    required this.floorId,
  });

  @override
  List<Object?> get props => [blockId, floorId];
}

class LoadAllUsersEvent extends AdminEvent {}

class InitializeDummyDataEvent extends AdminEvent {}

class AddManagerEvent extends AdminEvent {
  final String name;
  final String email;
  final String mobileNumber;
  final String password;
  final File? profilePic;
  final File? idProof;

  const AddManagerEvent({
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.password,
    this.profilePic,
    this.idProof,
  });

  @override
  List<Object?> get props =>
      [name, email, mobileNumber, password, profilePic, idProof];
}

class UpdateManagerEvent extends AdminEvent {
  final String managerId;
  final String? name;
  final String? email;
  final String? mobileNumber;
  final String? password;
  final File? profilePic;
  final File? idProof;

  const UpdateManagerEvent({
    required this.managerId,
    this.name,
    this.email,
    this.mobileNumber,
    this.password,
    this.profilePic,
    this.idProof,
  });

  @override
  List<Object?> get props =>
      [managerId, name, email, mobileNumber, password, profilePic, idProof];
}

class DeleteManagerEvent extends AdminEvent {
  final String managerId;

  const DeleteManagerEvent({required this.managerId});

  @override
  List<Object?> get props => [managerId];
}

class AddSecurityEvent extends AdminEvent {
  final String name;
  final String email;
  final String mobileNumber;
  final String password;
  final File? profilePic;
  final File? idProof;

  const AddSecurityEvent({
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.password,
    this.profilePic,
    this.idProof,
  });

  @override
  List<Object?> get props =>
      [name, email, mobileNumber, password, profilePic, idProof];
}

class UpdateSecurityEvent extends AdminEvent {
  final String securityId;
  final String? name;
  final String? email;
  final String? mobileNumber;
  final String? password;
  final File? profilePic;
  final File? idProof;

  const UpdateSecurityEvent({
    required this.securityId,
    this.name,
    this.email,
    this.mobileNumber,
    this.password,
    this.profilePic,
    this.idProof,
  });

  @override
  List<Object?> get props =>
      [securityId, name, email, mobileNumber, password, profilePic, idProof];
}

class DeleteSecurityEvent extends AdminEvent {
  final String securityId;

  const DeleteSecurityEvent({required this.securityId});

  @override
  List<Object?> get props => [securityId];
}

class AddUserEvent extends AdminEvent {
  final String name;
  final String email;
  final String mobileNumber;
  final String? block;
  final String? floor;
  final String? roomNumber;
  final FamilyType? familyType;

  const AddUserEvent({
    required this.name,
    required this.email,
    required this.mobileNumber,
    this.block,
    this.floor,
    this.roomNumber,
    this.familyType,
  });

  @override
  List<Object?> get props =>
      [name, email, mobileNumber, block, floor, roomNumber, familyType];
}

class BlockUserEvent extends AdminEvent {
  final String userId;

  const BlockUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UnblockUserEvent extends AdminEvent {
  final String userId;

  const UnblockUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class DeleteUserEvent extends AdminEvent {
  final String userId;

  const DeleteUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ToggleUserActiveEvent extends AdminEvent {
  final String userId;

  const ToggleUserActiveEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserStatusEvent extends AdminEvent {
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

class ToggleBlockActiveEvent extends AdminEvent {
  final String blockId;

  const ToggleBlockActiveEvent(this.blockId);

  @override
  List<Object?> get props => [blockId];
}

class ToggleRoomOccupiedEvent extends AdminEvent {
  final String blockId;
  final String floorId;
  final String roomId;
  final bool isOccupied;

  const ToggleRoomOccupiedEvent({
    required this.blockId,
    required this.floorId,
    required this.roomId,
    required this.isOccupied,
  });

  @override
  List<Object?> get props => [blockId, floorId, roomId, isOccupied];
}

// States
abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<BlockModel> blocks;
  final List<UserModel> allUsers;
  final List<UserModel> managers;
  final List<UserModel> securityStaff;
  final List<UserModel> regularUsers;

  const AdminLoaded({
    required this.blocks,
    required this.allUsers,
    required this.managers,
    required this.securityStaff,
    required this.regularUsers,
  });

  @override
  List<Object?> get props =>
      [blocks, allUsers, managers, securityStaff, regularUsers];
}

class AdminError extends AdminState {
  final String message;

  const AdminError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AuthRepository _authRepository = AuthRepository();
  final ApiService _apiService = ApiService();

  AdminBloc() : super(AdminInitial()) {
    on<LoadBlocksEvent>(_onLoadBlocks);
    on<CreateBlockEvent>(_onCreateBlock);
    on<AddFloorEvent>(_onAddFloor);
    on<LoadAllUsersEvent>(_onLoadAllUsers);
    on<InitializeDummyDataEvent>(_onInitializeDummyData);
    // on<AddManagerEvent>(_onAddManager);
    // on<UpdateManagerEvent>(_onUpdateManager);
    // on<DeleteManagerEvent>(_onDeleteManager);
    on<AddSecurityEvent>(_onAddSecurity);
    on<UpdateSecurityEvent>(_onUpdateSecurity);
    on<DeleteSecurityEvent>(_onDeleteSecurity);
    on<AddUserEvent>(_onAddUser);
    on<BlockUserEvent>(_onBlockUser);
    on<UnblockUserEvent>(_onUnblockUser);
    on<DeleteUserEvent>(_onDeleteUser);
    on<ToggleUserActiveEvent>(_onToggleUserActive);
    on<UpdateUserStatusEvent>(_onUpdateUserStatus);
    on<ToggleBlockActiveEvent>(_onToggleBlockActive);
    on<AddRoomEvent>(_onAddRoom);
    on<EditBlockEvent>(_onEditBlock);
    on<DeleteBlockEvent>(_onDeleteBlock);
    on<EditFloorEvent>(_onEditFloor);
    on<DeleteFloorEvent>(_onDeleteFloor);
    on<ToggleRoomOccupiedEvent>(_onToggleRoomOccupied);
  }

  Future<void> _onLoadBlocks(
    LoadBlocksEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      // Fetch blocks from backend
      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      // Fetch users from backend
      final users = await _authRepository.getAllUsers();
      final managers =
          users.where((u) => u.userType == UserType.manager).toList();
      final securityStaff =
          users.where((u) => u.userType == UserType.security).toList();
      final regularUsers =
          users.where((u) => u.userType == UserType.user).toList();

      emit(AdminLoaded(
        blocks: blocks,
        allUsers: users,
        managers: managers,
        securityStaff: securityStaff,
        regularUsers: regularUsers,
      ));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onLoadAllUsers(
    LoadAllUsersEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is AdminLoaded) {
        final users = await _authRepository.getAllUsers();
        final managers =
            users.where((u) => u.userType == UserType.manager).toList();
        final securityStaff =
            users.where((u) => u.userType == UserType.security).toList();
        final regularUsers =
            users.where((u) => u.userType == UserType.user).toList();
        emit(AdminLoaded(
          blocks: currentState.blocks,
          allUsers: users,
          managers: managers,
          securityStaff: securityStaff,
          regularUsers: regularUsers,
        ));
      }
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onInitializeDummyData(
    InitializeDummyDataEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final users = await _authRepository.getAllUsers();

      // Indian names list - comprehensive
      final indianNames = [
        'Rajesh Kumar',
        'Priya Sharma',
        'Amit Patel',
        'Sneha Reddy',
        'Vikram Singh',
        'Anjali Gupta',
        'Rahul Verma',
        'Kavita Nair',
        'Suresh Iyer',
        'Meera Joshi',
        'Arjun Desai',
        'Divya Menon',
        'Karan Malhotra',
        'Pooja Kapoor',
        'Nikhil Rao',
        'Shreya Agarwal',
        'Rohan Mehta',
        'Neha Chaturvedi',
        'Aditya Shah',
        'Tanvi Trivedi',
        'Vishal Pandey',
        'Isha Bansal',
        'Manish Tiwari',
        'Riya Saxena',
        'Harsh Dubey',
        'Ananya Mishra',
        'Siddharth Jain',
        'Kritika Sinha',
        'Abhishek Yadav',
        'Swati Goyal',
        'Varun Khanna',
        'Aishwarya Rana',
        'Kunal Bhatia',
        'Ritika Chopra',
        'Mohit Agarwal',
        'Sakshi Dutta',
        'Ravi Shankar',
        'Nisha Varma',
        'Gaurav Oberoi',
        'Preeti Nanda',
        'Deepak Sharma',
        'Sunita Mehta',
        'Ramesh Kumar',
        'Kiran Patel',
        'Lakshmi Reddy',
        'Suresh Kumar',
        'Geeta Singh',
        'Manoj Verma',
        'Radha Nair',
        'Venkatesh Iyer',
      ];

      // Check if dummy data already exists
      final existingUsers =
          users.where((u) => u.userType == UserType.user).length;
      if (existingUsers < 20) {
        // Create dummy users
        for (int i = 0; i < indianNames.length; i++) {
          final name = indianNames[i];
          final email =
              '${name.toLowerCase().replaceAll(' ', '.')}@apartment.com';
          final mobile = '9${(1000000000 + i).toString().substring(1)}';

          final user = UserModel(
            id: 'user_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: name,
            username: name.toLowerCase().replaceAll(' ', '_'),
            email: email,
            mobileNumber: mobile,
            userType: UserType.user,
            status: i % 3 == 0
                ? AccountStatus.approved
                : (i % 3 == 1 ? AccountStatus.pending : AccountStatus.rejected),
            block: ['A', 'B', 'C'][i % 3],
            floor: '${(i % 5) + 1}',
            roomNumber: '${(i % 10) + 1}',
            familyType: i % 2 == 0 ? FamilyType.family : FamilyType.bachelor,
          );

          await _authRepository.saveUser(user);
        }

        // Create dummy managers with Indian names
        final managerNames = [
          'Rajesh Kumar Manager',
          'Priya Sharma Manager',
          'Amit Patel Manager',
          'Sneha Reddy Manager',
          'Vikram Singh Manager'
        ];
        for (int i = 0; i < managerNames.length; i++) {
          final name = managerNames[i];
          final email =
              '${name.toLowerCase().replaceAll(' ', '.')}@apartment.com';
          final mobile = '8${(1000000000 + i).toString().substring(1)}';

          final manager = UserModel(
            id: 'manager_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: name,
            username: name.toLowerCase().replaceAll(' ', '_'),
            email: email,
            mobileNumber: mobile,
            userType: UserType.manager,
            status: AccountStatus.approved,
          );

          await _authRepository.saveUser(manager);
        }

        // Create dummy security with Indian names
        final securityNames = [
          'Vikram Singh Security',
          'Suresh Kumar Security',
          'Ravi Shankar Security',
          'Manoj Verma Security',
          'Venkatesh Iyer Security',
          'Deepak Sharma Security'
        ];
        for (int i = 0; i < securityNames.length; i++) {
          final name = securityNames[i];
          final email =
              '${name.toLowerCase().replaceAll(' ', '.')}@apartment.com';
          final mobile = '7${(1000000000 + i).toString().substring(1)}';

          final security = UserModel(
            id: 'security_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: name,
            username: name.toLowerCase().replaceAll(' ', '_'),
            email: email,
            mobileNumber: mobile,
            userType: UserType.security,
            status: AccountStatus.approved,
          );

          await _authRepository.saveUser(security);
        }

        // Create dummy blocks if they don't exist
        final blocks = await _getBlocks();
        if (blocks.isEmpty) {
          final blockLetters = ['A', 'B', 'C', 'D'];
          for (final letter in blockLetters) {
            final newBlock = BlockModel(
              id: Uuid().v4(),
              name: letter,
              floors: [],
            );
            blocks.add(newBlock);
          }
          await _saveBlocks(blocks);
        }
      }

      // Reload all data
      add(LoadAllUsersEvent());
      add(LoadBlocksEvent());
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  // Future<void> _onAddManager(
  //   AddManagerEvent event,
  //   Emitter<AdminState> emit,
  // ) async {
  //   if (isClosed) return;
  //   emit(AdminLoading());
  //   try {
  //     final username = event.name.toLowerCase().replaceAll(' ', '_');

  //     final response = await _apiService.registerUser(
  //       name: event.name,
  //       username: username,
  //       email: event.email,
  //       password: event.password,
  //       mobileNumber: event.mobileNumber,
  //       userType: 'manager',
  //       profilePic: event.profilePic,
  //       aadhaarFront: event.idProof, // Using aadhaarFront field for ID proof
  //     );

  //     if (response['success'] == true) {
  //       add(LoadAllUsersEvent());
  //       add(LoadBlocksEvent());
  //     } else {
  //       if (!isClosed) {
  //         emit(AdminError(
  //             message: response['error'] ?? 'Failed to add manager'));
  //       }
  //     }
  //   } catch (e) {
  //     if (!isClosed) {
  //       emit(AdminError(message: e.toString()));
  //     }
  //   }
  // }

  // Future<void> _onUpdateManager(
  //   UpdateManagerEvent event,
  //   Emitter<AdminState> emit,
  // ) async {
  //   if (isClosed) return;
  //   emit(AdminLoading());
  //   try {
  //     final response = await _apiService.updateManager(
  //       managerId: event.managerId,
  //       name: event.name,
  //       email: event.email,
  //       mobileNumber: event.mobileNumber,
  //       password: event.password,
  //       profilePic: event.profilePic,
  //       idProof: event.idProof,
  //     );

  //     if (response['success'] == true) {
  //       add(LoadAllUsersEvent());
  //       add(LoadBlocksEvent());
  //     } else {
  //       if (!isClosed) {
  //         emit(AdminError(
  //             message: response['error'] ?? 'Failed to update manager'));
  //       }
  //     }
  //   } catch (e) {
  //     if (!isClosed) {
  //       emit(AdminError(message: e.toString()));
  //     }
  //   }
  // }

  // Future<void> _onDeleteManager(
  //   DeleteManagerEvent event,
  //   Emitter<AdminState> emit,
  // ) async {
  //   if (isClosed) return;
  //   emit(AdminLoading());
  //   try {
  //     final response = await _apiService.deleteManager(event.managerId);

  //     if (response['success'] == true) {
  //       add(LoadAllUsersEvent());
  //       add(LoadBlocksEvent());
  //     } else {
  //       if (!isClosed) {
  //         emit(AdminError(
  //             message: response['error'] ?? 'Failed to delete manager'));
  //       }
  //     }
  //   } catch (e) {
  //     if (!isClosed) {
  //       emit(AdminError(message: e.toString()));
  //     }
  //   }
  // }

  Future<void> _onAddSecurity(
    AddSecurityEvent event,
    Emitter<AdminState> emit,
  ) async {
    if (isClosed) return;
    emit(AdminLoading());
    try {
      final username = event.name.toLowerCase().replaceAll(' ', '_');

      final response = await _apiService.registerUser(
        name: event.name,
        username: username,
        email: event.email,
        password: event.password,
        mobileNumber: event.mobileNumber,
        userType: 'security',
        profilePic: event.profilePic,
        aadhaarFront: event.idProof, // Using aadhaarFront field for ID proof
      );

      if (response['success'] == true) {
        add(LoadAllUsersEvent());
        add(LoadBlocksEvent());
      } else {
        if (!isClosed) {
          emit(AdminError(
              message: response['error'] ?? 'Failed to add security staff'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminError(message: e.toString()));
      }
    }
  }

  Future<void> _onUpdateSecurity(
    UpdateSecurityEvent event,
    Emitter<AdminState> emit,
  ) async {
    if (isClosed) return;
    emit(AdminLoading());
    try {
      final response = await _apiService.updateSecurity(
        securityId: event.securityId,
        name: event.name,
        email: event.email,
        mobileNumber: event.mobileNumber,
        password: event.password,
        profilePic: event.profilePic,
        idProof: event.idProof,
      );

      if (response['success'] == true) {
        add(LoadAllUsersEvent());
        add(LoadBlocksEvent());
      } else {
        if (!isClosed) {
          emit(AdminError(
              message: response['error'] ?? 'Failed to update security staff'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminError(message: e.toString()));
      }
    }
  }

  Future<void> _onDeleteSecurity(
    DeleteSecurityEvent event,
    Emitter<AdminState> emit,
  ) async {
    if (isClosed) return;
    emit(AdminLoading());
    try {
      final response = await _apiService.deleteSecurity(event.securityId);

      if (response['success'] == true) {
        add(LoadAllUsersEvent());
        add(LoadBlocksEvent());
      } else {
        if (!isClosed) {
          emit(AdminError(
              message: response['error'] ?? 'Failed to delete security staff'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminError(message: e.toString()));
      }
    }
  }

  Future<void> _onAddUser(
    AddUserEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: event.name,
        username: event.name.toLowerCase().replaceAll(' ', '_'),
        email: event.email,
        mobileNumber: event.mobileNumber,
        userType: UserType.user,
        status: AccountStatus.pending,
        block: event.block,
        floor: event.floor,
        roomNumber: event.roomNumber,
        familyType: event.familyType,
      );

      await _authRepository.saveUser(user);
      add(LoadAllUsersEvent());
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onBlockUser(
    BlockUserEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final users = await _authRepository.getAllUsers();
      final userIndex = users.indexWhere((u) => u.id == event.userId);
      if (userIndex >= 0) {
        final user = users[userIndex];
        final updatedUser = user.copyWith(status: AccountStatus.rejected);
        await _authRepository.saveUser(updatedUser);
        add(LoadAllUsersEvent());
      }
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUserEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final users = await _authRepository.getAllUsers();
      final userIndex = users.indexWhere((u) => u.id == event.userId);
      if (userIndex >= 0) {
        final user = users[userIndex];
        final updatedUser = user.copyWith(status: AccountStatus.approved);
        await _authRepository.saveUser(updatedUser);
        add(LoadAllUsersEvent());
      }
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final users = await _authRepository.getAllUsers();
      users.removeWhere((u) => u.id == event.userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'users_list',
        jsonEncode(users.map((u) => u.toJson()).toList()),
      );
      add(LoadAllUsersEvent());
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onCreateBlock(
    CreateBlockEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      // Emit loading state
      if (!isClosed) {
        emit(AdminLoading());
      }

      // Create block via backend API
      final response = await _apiService.createBlock(event.blockName);

      if (response['success'] != true) {
        if (!isClosed) {
          emit(AdminError(
              message: response['error'] ?? 'Failed to create block'));
        }
        return;
      }

      final blockId = response['block']?['_id']?.toString() ??
          response['block']?['id']?.toString();

      if (blockId == null) {
        if (!isClosed) {
          emit(AdminError(message: 'Failed to get block ID after creation'));
        }
        return;
      }

      // If number of floors is provided, create that many floors
      if (event.numberOfFloors != null && event.numberOfFloors! > 0) {
        int successCount = 0;
        int failCount = 0;

        // Create floors from 1 to numberOfFloors
        for (int i = 1; i <= event.numberOfFloors!; i++) {
          if (isClosed) break; // Stop if bloc is closed

          try {
            final floorResponse = await _apiService.addFloor(
              blockId: blockId,
              floorNumber: i.toString(),
              roomConfigurations: [], // Empty floor, rooms will be added later
            );

            // Check if floor creation was successful
            if (floorResponse['success'] == true) {
              successCount++;
            } else {
              failCount++;
              debugPrint(
                  'Failed to create floor $i: ${floorResponse['error']}');
            }
          } catch (e) {
            failCount++;
            debugPrint('Error creating floor $i: $e');
          }
        }

        // If all floors failed, show error but still continue
        if (failCount == event.numberOfFloors! && successCount == 0) {
          if (!isClosed) {
            emit(AdminError(
                message: 'Block created but failed to create floors'));
            return;
          }
        }
      }

      // Reload blocks from backend
      if (isClosed) return;

      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      // Get users
      final users = await _authRepository.getAllUsers();
      final managers =
          users.where((u) => u.userType == UserType.manager).toList();
      final securityStaff =
          users.where((u) => u.userType == UserType.security).toList();
      final regularUsers =
          users.where((u) => u.userType == UserType.user).toList();

      // Emit loaded state
      if (!isClosed) {
        emit(AdminLoaded(
          blocks: blocks,
          allUsers: users,
          managers: managers,
          securityStaff: securityStaff,
          regularUsers: regularUsers,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminError(message: e.toString()));
      }
    }
  }

  Future<void> _onAddFloor(
    AddFloorEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;

      // Add floor via backend API
      final response = await _apiService.addFloor(
        blockId: event.blockId,
        floorNumber: event.floorNumber,
        roomConfigurations: event.roomConfigurations,
        roomNumber: event.roomNumber,
      );

      if (response['success'] != true) {
        emit(AdminError(message: response['error'] ?? 'Failed to add floor'));
        return;
      }

      // Reload blocks from backend
      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      if (currentState is AdminLoaded) {
        final users = await _authRepository.getAllUsers();
        final managers =
            users.where((u) => u.userType == UserType.manager).toList();
        final securityStaff =
            users.where((u) => u.userType == UserType.security).toList();
        final regularUsers =
            users.where((u) => u.userType == UserType.user).toList();
        emit(AdminLoaded(
          blocks: blocks,
          allUsers: users,
          managers: managers,
          securityStaff: securityStaff,
          regularUsers: regularUsers,
        ));
      } else {
        final users = await _authRepository.getAllUsers();
        final managers =
            users.where((u) => u.userType == UserType.manager).toList();
        final securityStaff =
            users.where((u) => u.userType == UserType.security).toList();
        final regularUsers =
            users.where((u) => u.userType == UserType.user).toList();
        emit(AdminLoaded(
          blocks: blocks,
          allUsers: users,
          managers: managers,
          securityStaff: securityStaff,
          regularUsers: regularUsers,
        ));
      }
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onToggleUserActive(
    ToggleUserActiveEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! AdminLoaded) return;

      final response = await _apiService.toggleUserActive(event.userId);

      if (response['success'] != true) {
        final err = response['error'] ?? '';
        // If user not found on server (likely a local-only/dummy user), reload users to sync UI
        if (err.toLowerCase().contains('not found')) {
          add(LoadAllUsersEvent());
          return;
        }
        emit(AdminError(
            message: err.isNotEmpty ? err : 'Failed to toggle user status'));
        return;
      }

      // Reload users from backend
      final users = await _authRepository.getAllUsers();
      final managers =
          users.where((u) => u.userType == UserType.manager).toList();
      final securityStaff =
          users.where((u) => u.userType == UserType.security).toList();
      final regularUsers =
          users.where((u) => u.userType == UserType.user).toList();

      emit(AdminLoaded(
        blocks: currentState.blocks,
        allUsers: users,
        managers: managers,
        securityStaff: securityStaff,
        regularUsers: regularUsers,
      ));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onUpdateUserStatus(
    UpdateUserStatusEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final response = await _apiService.updateUserStatus(
        event.userId,
        event.status.name,
        block: event.block,
        floor: event.floor,
        roomNumber: event.roomNumber,
      );
      if (response['success'] == true) {
        add(LoadAllUsersEvent());
      } else {
        if (!isClosed) {
          emit(AdminError(
              message: response['error'] ?? 'Failed to update user status'));
        }
        add(LoadAllUsersEvent());
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminError(message: e.toString()));
      }
      add(LoadAllUsersEvent());
    }
  }

  Future<void> _onToggleBlockActive(
    ToggleBlockActiveEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! AdminLoaded) return;

      final response = await _apiService.toggleBlockActive(event.blockId);

      if (response['success'] != true) {
        emit(AdminError(
            message: response['error'] ?? 'Failed to toggle block status'));
        return;
      }

      // Reload blocks from backend
      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      emit(AdminLoaded(
        blocks: blocks,
        allUsers: currentState.allUsers,
        managers: currentState.managers,
        securityStaff: currentState.securityStaff,
        regularUsers: currentState.regularUsers,
      ));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onAddRoom(
    AddRoomEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! AdminLoaded) return;

      final response = await _apiService.addRoom(
        blockId: event.blockId,
        floorId: event.floorId,
        roomNumber: event.roomNumber,
        roomType: event.roomType,
      );

      if (response['success'] != true) {
        emit(AdminError(message: response['error'] ?? 'Failed to add room'));
        return;
      }

      // Reload blocks from backend
      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      emit(AdminLoaded(
        blocks: blocks,
        allUsers: currentState.allUsers,
        managers: currentState.managers,
        securityStaff: currentState.securityStaff,
        regularUsers: currentState.regularUsers,
      ));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onEditBlock(
    EditBlockEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! AdminLoaded) return;

      final response = await _apiService.updateBlock(event.blockId, event.name);

      if (response['success'] != true) {
        emit(
            AdminError(message: response['error'] ?? 'Failed to update block'));
        return;
      }

      // Reload blocks from backend
      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      emit(AdminLoaded(
        blocks: blocks,
        allUsers: currentState.allUsers,
        managers: currentState.managers,
        securityStaff: currentState.securityStaff,
        regularUsers: currentState.regularUsers,
      ));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onDeleteBlock(
    DeleteBlockEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! AdminLoaded) return;

      final response = await _apiService.deleteBlock(event.blockId);

      if (response['success'] != true) {
        emit(
            AdminError(message: response['error'] ?? 'Failed to delete block'));
        return;
      }

      // Reload blocks from backend
      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      emit(AdminLoaded(
        blocks: blocks,
        allUsers: currentState.allUsers,
        managers: currentState.managers,
        securityStaff: currentState.securityStaff,
        regularUsers: currentState.regularUsers,
      ));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onEditFloor(
    EditFloorEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! AdminLoaded) return;

      final response = await _apiService.updateFloor(
        blockId: event.blockId,
        floorId: event.floorId,
        floorNumber: event.floorNumber,
      );

      if (response['success'] != true) {
        emit(
            AdminError(message: response['error'] ?? 'Failed to update floor'));
        return;
      }

      // Reload blocks from backend
      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      emit(AdminLoaded(
        blocks: blocks,
        allUsers: currentState.allUsers,
        managers: currentState.managers,
        securityStaff: currentState.securityStaff,
        regularUsers: currentState.regularUsers,
      ));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onDeleteFloor(
    DeleteFloorEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! AdminLoaded) return;

      final response = await _apiService.deleteFloor(
        blockId: event.blockId,
        floorId: event.floorId,
      );

      if (response['success'] != true) {
        emit(
            AdminError(message: response['error'] ?? 'Failed to delete floor'));
        return;
      }

      // Reload blocks from backend
      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      emit(AdminLoaded(
        blocks: blocks,
        allUsers: currentState.allUsers,
        managers: currentState.managers,
        securityStaff: currentState.securityStaff,
        regularUsers: currentState.regularUsers,
      ));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onToggleRoomOccupied(
    ToggleRoomOccupiedEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! AdminLoaded) return;

      final response = await _apiService.updateRoom(
        blockId: event.blockId,
        floorId: event.floorId,
        roomId: event.roomId,
        isOccupied: event.isOccupied,
      );

      if (response['success'] != true) {
        emit(AdminError(
            message: response['error'] ?? 'Failed to update room status'));
        return;
      }

      // Reload blocks from backend
      final blocksResponse = await _apiService.getAllBlocks();
      final List<BlockModel> blocks = [];
      if (blocksResponse['success'] == true &&
          blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'];
        blocks.addAll(blocksList.map((b) => BlockModel.fromJson(b)).toList());
      }

      emit(AdminLoaded(
        blocks: blocks,
        allUsers: currentState.allUsers,
        managers: currentState.managers,
        securityStaff: currentState.securityStaff,
        regularUsers: currentState.regularUsers,
      ));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  // Keep these methods for backward compatibility, but they're no longer used
  // All block operations now go through the backend API
  Future<List<BlockModel>> _getBlocks() async {
    // This method is deprecated - use API instead
    final blocksResponse = await _apiService.getAllBlocks();
    if (blocksResponse['success'] == true && blocksResponse['blocks'] != null) {
      final List<dynamic> blocksList = blocksResponse['blocks'];
      return blocksList.map((b) => BlockModel.fromJson(b)).toList();
    }
    return [];
  }

  Future<void> _saveBlocks(List<BlockModel> blocks) async {
    // This method is deprecated - blocks are saved via API
    // Keeping for backward compatibility
  }
}
