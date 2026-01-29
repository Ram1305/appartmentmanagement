import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/models/visitor_model.dart';
import '../../../../core/models/block_model.dart';
import '../../../../core/models/kid_exit_model.dart';
import '../../../../core/services/api_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

// Events
abstract class SecurityEvent extends Equatable {
  const SecurityEvent();

  @override
  List<Object?> get props => [];
}

class LoadSecurityDataEvent extends SecurityEvent {}

class AddVisitorEvent extends SecurityEvent {
  final String name;
  final String mobileNumber;
  final VisitorType type;
  final String block;
  final String homeNumber;
  final String? image;
  final String? purposeOfVisit;
  final String? vehicleNumber;

  const AddVisitorEvent({
    required this.name,
    required this.mobileNumber,
    required this.type,
    required this.block,
    required this.homeNumber,
    this.image,
    this.purposeOfVisit,
    this.vehicleNumber,
  });

  @override
  List<Object?> get props => [name, mobileNumber, type, block, homeNumber, image, purposeOfVisit, vehicleNumber];
}

class ApproveVisitorEvent extends SecurityEvent {
  final String visitorId;

  const ApproveVisitorEvent({required this.visitorId});

  @override
  List<Object?> get props => [visitorId];
}

class ClearSecurityErrorEvent extends SecurityEvent {}

// States
abstract class SecurityState extends Equatable {
  const SecurityState();

  @override
  List<Object?> get props => [];
}

class SecurityInitial extends SecurityState {}

class SecurityLoading extends SecurityState {}

class SecurityLoaded extends SecurityState {
  final List<VisitorModel> visitors;
  final List<BlockModel> blocks;
  final List<KidExitModel> kidExits;
  /// Non-null when the last add-visitor API call failed (visitor may still be shown locally).
  final String? lastAddVisitorError;

  const SecurityLoaded({
    required this.visitors,
    required this.blocks,
    this.kidExits = const [],
    this.lastAddVisitorError,
  });

  @override
  List<Object?> get props => [visitors, blocks, kidExits, lastAddVisitorError];
}

// BLoC
class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  static const String _visitorsKey = 'visitors_list';
  static const String _blocksKey = 'blocks_list';

  final ApiService _apiService = ApiService();

  SecurityBloc() : super(SecurityInitial()) {
    on<LoadSecurityDataEvent>(_onLoadSecurityData);
    on<AddVisitorEvent>(_onAddVisitor);
    on<ApproveVisitorEvent>(_onApproveVisitor);
    on<ClearSecurityErrorEvent>(_onClearSecurityError);
  }

  void _onClearSecurityError(ClearSecurityErrorEvent event, Emitter<SecurityState> emit) {
    final current = state;
    if (current is SecurityLoaded && current.lastAddVisitorError != null) {
      emit(SecurityLoaded(visitors: current.visitors, blocks: current.blocks, kidExits: current.kidExits));
    }
  }

  Future<void> _onLoadSecurityData(
    LoadSecurityDataEvent event,
    Emitter<SecurityState> emit,
  ) async {
    emit(SecurityLoading());
    try {
      List<VisitorModel> visitors = [];
      List<BlockModel> blocks = [];
      List<KidExitModel> kidExits = [];

      // Fetch all visitors from backend (dashboard filters Today / Upcoming / View All client-side)
      final visitorsResponse = await _apiService.getSecurityVisitors();
      if (visitorsResponse['success'] == true && visitorsResponse['visitors'] != null) {
        final List<dynamic> list = visitorsResponse['visitors'] as List<dynamic>;
        visitors = list
            .map((v) => VisitorModel.fromJson(Map<String, dynamic>.from(v as Map)))
            .toList();
      }

      // Fetch blocks from backend so Add Visitor block dropdown has data
      final blocksResponse = await _apiService.getAllBlocks();
      if (blocksResponse['success'] == true && blocksResponse['blocks'] != null) {
        final List<dynamic> blocksList = blocksResponse['blocks'] as List<dynamic>;
        blocks = blocksList
            .map((b) => BlockModel.fromJson(Map<String, dynamic>.from(b as Map)))
            .toList();
        await _saveBlocks(blocks);
      }

      // Fallback: use cached blocks from prefs if API returned none
      if (blocks.isEmpty) {
        blocks = await _getBlocks();
      }

      // Kid exits: security sees all (today by default for dashboard)
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final kidExitsResponse = await _apiService.getKidExits(date: todayStr);
      if (kidExitsResponse['success'] == true && kidExitsResponse['kidExits'] != null) {
        final List<dynamic> list = kidExitsResponse['kidExits'] as List<dynamic>;
        kidExits = list
            .map((e) => KidExitModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      emit(SecurityLoaded(visitors: visitors, blocks: blocks, kidExits: kidExits));
    } catch (e) {
      // On error: try local cache for both (no lastAddVisitorError on load)
      try {
        final visitors = await _getVisitors();
        final blocks = await _getBlocks();
        emit(SecurityLoaded(visitors: visitors, blocks: blocks, kidExits: []));
      } catch (_) {
        emit(SecurityLoaded(visitors: [], blocks: [], kidExits: []));
      }
    }
  }

  Future<void> _onAddVisitor(
    AddVisitorEvent event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      // Start from current state so API-loaded visitors are kept; only use cache when not yet loaded
      List<VisitorModel> visitors;
      final current = state;
      if (current is SecurityLoaded) {
        visitors = List<VisitorModel>.from(current.visitors);
      } else {
        visitors = await _getVisitors();
      }

      // Persist to backend so visitor still appears after close/reopen
      final mobileDigits = event.mobileNumber.replaceAll(RegExp(r'\D'), '');
      final mobile10 = mobileDigits.length >= 10 ? mobileDigits.substring(mobileDigits.length - 10) : event.mobileNumber.trim();
      final payload = <String, dynamic>{
        'name': event.name,
        'mobileNumber': mobile10,
        'category': 'outsider',
        'type': event.type.name,
        'block': event.block,
        'homeNumber': event.homeNumber,
        'visitTime': DateTime.now().toIso8601String(),
        if (event.purposeOfVisit != null && event.purposeOfVisit!.isNotEmpty) 'reasonForVisit': event.purposeOfVisit,
        if (event.vehicleNumber != null && event.vehicleNumber!.isNotEmpty) 'vehicleNumber': event.vehicleNumber,
        if (event.image != null && event.image!.isNotEmpty) 'image': event.image,
      };
      final response = await _apiService.createSecurityVisitor(payload);

      String? apiError;
      VisitorModel newVisitor;
      if (response['success'] == true && response['visitor'] != null) {
        final raw = response['visitor'];
        final map = Map<String, dynamic>.from(raw is Map ? raw as Map : {});
        if (!map.containsKey('id') && map.containsKey('_id')) {
          map['id'] = map['_id'].toString();
        }
        newVisitor = VisitorModel.fromJson(map);
      } else {
        // Offline/API failure: add locally so user sees it; will not persist across reopen until API is available
        apiError = response['error'] as String? ?? 'Could not save visitor to server. You may be offline.';
        final otp = _generateOTP();
        final visitorId = const Uuid().v4();
        final qrData = jsonEncode({
          'visitorId': visitorId,
          'name': event.name,
          'mobileNumber': event.mobileNumber,
          'block': event.block,
          'homeNumber': event.homeNumber,
          'visitTime': DateTime.now().toIso8601String(),
          'otp': otp,
        });
        newVisitor = VisitorModel(
          id: visitorId,
          name: event.name,
          mobileNumber: event.mobileNumber,
          category: VisitorCategory.outsider,
          type: event.type,
          block: event.block,
          homeNumber: event.homeNumber,
          visitTime: DateTime.now(),
          otp: otp,
          qrCode: qrData,
          image: event.image,
          reasonForVisit: event.purposeOfVisit,
          vehicleNumber: event.vehicleNumber,
          approvalStatus: VisitorApprovalStatus.pending,
        );
      }

      visitors.add(newVisitor);
      await _saveVisitors(visitors);
      final blocks = await _getBlocks();
      emit(SecurityLoaded(visitors: visitors, blocks: blocks, kidExits: current.kidExits, lastAddVisitorError: apiError));
    } catch (e) {
      // Exception during API or parsing: add visitor locally and surface error
      final current = state;
      List<VisitorModel> visitors = current is SecurityLoaded ? List<VisitorModel>.from(current.visitors) : await _getVisitors();
      final blocks = current is SecurityLoaded ? current.blocks : await _getBlocks();
      final otp = _generateOTP();
      final visitorId = const Uuid().v4();
      final qrData = jsonEncode({
        'visitorId': visitorId,
        'name': event.name,
        'mobileNumber': event.mobileNumber,
        'block': event.block,
        'homeNumber': event.homeNumber,
        'visitTime': DateTime.now().toIso8601String(),
        'otp': otp,
      });
      final newVisitor = VisitorModel(
        id: visitorId,
        name: event.name,
        mobileNumber: event.mobileNumber,
        category: VisitorCategory.outsider,
        type: event.type,
        block: event.block,
        homeNumber: event.homeNumber,
        visitTime: DateTime.now(),
        otp: otp,
        qrCode: qrData,
        image: event.image,
        reasonForVisit: event.purposeOfVisit,
        vehicleNumber: event.vehicleNumber,
        approvalStatus: VisitorApprovalStatus.pending,
      );
      visitors.add(newVisitor);
      await _saveVisitors(visitors);
      emit(SecurityLoaded(visitors: visitors, blocks: blocks, kidExits: current.kidExits, lastAddVisitorError: 'Could not save to server: ${e.toString()}'));
    }
  }

  Future<void> _onApproveVisitor(
    ApproveVisitorEvent event,
    Emitter<SecurityState> emit,
  ) async {
    final current = state;
    if (current is! SecurityLoaded) return;
    try {
      final response = await _apiService.updateVisitorApproval(event.visitorId, 'approved');
      if (response['success'] == true) {
        final visitors = List<VisitorModel>.from(current.visitors);
        final idx = visitors.indexWhere((v) => v.id == event.visitorId);
        if (idx >= 0) {
          visitors[idx] = visitors[idx].copyWith(approvalStatus: VisitorApprovalStatus.approved);
          await _saveVisitors(visitors);
          emit(SecurityLoaded(visitors: visitors, blocks: current.blocks, kidExits: current.kidExits, lastAddVisitorError: current.lastAddVisitorError));
        }
      } else {
        final err = response['error'] as String? ?? 'Could not approve visitor';
        emit(SecurityLoaded(visitors: current.visitors, blocks: current.blocks, kidExits: current.kidExits, lastAddVisitorError: err));
      }
    } catch (e) {
      emit(SecurityLoaded(visitors: current.visitors, blocks: current.blocks, kidExits: current.kidExits, lastAddVisitorError: 'Failed to approve: ${e.toString()}'));
    }
  }

  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
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

  Future<List<BlockModel>> _getBlocks() async {
    final prefs = await SharedPreferences.getInstance();
    final blocksJson = prefs.getString(_blocksKey);
    if (blocksJson != null) {
      final List<dynamic> blocksList = jsonDecode(blocksJson);
      return blocksList.map((b) => BlockModel.fromJson(b)).toList();
    }
    return [];
  }

  Future<void> _saveBlocks(List<BlockModel> blocks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _blocksKey,
      jsonEncode(blocks.map((b) => b.toJson()).toList()),
    );
  }
}

