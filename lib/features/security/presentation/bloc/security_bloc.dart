import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/models/visitor_model.dart';
import '../../../../core/models/block_model.dart';
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

  const SecurityLoaded({
    required this.visitors,
    required this.blocks,
  });

  @override
  List<Object?> get props => [visitors, blocks];
}

// BLoC
class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  static const String _visitorsKey = 'visitors_list';
  static const String _blocksKey = 'blocks_list';

  SecurityBloc() : super(SecurityInitial()) {
    on<LoadSecurityDataEvent>(_onLoadSecurityData);
    on<AddVisitorEvent>(_onAddVisitor);
  }

  Future<void> _onLoadSecurityData(
    LoadSecurityDataEvent event,
    Emitter<SecurityState> emit,
  ) async {
    emit(SecurityLoading());
    try {
      var visitors = await _getVisitors();
      final blocks = await _getBlocks();
      
      // Initialize dummy visitor data if empty
      if (visitors.isEmpty && blocks.isNotEmpty) {
        final indianVisitorNames = [
          'Ramesh Kumar', 'Sunita Devi', 'Manoj Singh', 'Kiran Patel', 'Lakshmi Reddy',
          'Suresh Verma', 'Geeta Sharma', 'Rajesh Nair', 'Priya Iyer', 'Amit Joshi',
          'Deepak Mehta', 'Anjali Desai', 'Vikram Menon', 'Sneha Malhotra', 'Rahul Kapoor',
        ];
        
        final visitorTypes = VisitorType.values;
        final blockNames = blocks.map((b) => b.name).toList();
        
        for (int i = 0; i < indianVisitorNames.length && i < 15; i++) {
          final visitor = VisitorModel(
            id: const Uuid().v4(),
            name: indianVisitorNames[i],
            mobileNumber: '9${(1000000000 + i).toString().substring(1)}',
            category: VisitorCategory.outsider,
            type: visitorTypes[i % visitorTypes.length],
            block: blockNames[i % blockNames.length],
            homeNumber: '${(i % 10) + 1}',
            visitTime: DateTime.now().subtract(Duration(hours: i)),
            otp: _generateOTP(),
          );
          visitors.add(visitor);
        }
        await _saveVisitors(visitors);
      }
      
      emit(SecurityLoaded(visitors: visitors, blocks: blocks));
    } catch (e) {
      emit(SecurityLoaded(visitors: [], blocks: []));
    }
  }

  Future<void> _onAddVisitor(
    AddVisitorEvent event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      final visitors = await _getVisitors();
      final otp = _generateOTP();
      
      // Generate visitor ID for QR code
      final visitorId = const Uuid().v4();
      
      // Create QR code data (JSON string with visitor info)
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
        category: VisitorCategory.outsider, // Security adds outsiders by default
        type: event.type,
        block: event.block,
        homeNumber: event.homeNumber,
        visitTime: DateTime.now(),
        otp: otp,
        qrCode: qrData,
        image: event.image,
        reasonForVisit: event.purposeOfVisit,
        vehicleNumber: event.vehicleNumber,
      );
      visitors.add(newVisitor);
      await _saveVisitors(visitors);
      final blocks = await _getBlocks();
      emit(SecurityLoaded(visitors: visitors, blocks: blocks));
    } catch (e) {
      // Handle error
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
}

