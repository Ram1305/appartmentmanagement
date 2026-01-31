import 'package:equatable/equatable.dart';

class BlockModel extends Equatable {
  final String id;
  final String name;
  final List<FloorModel> floors;
  final bool isActive;

  const BlockModel({
    required this.id,
    required this.name,
    required this.floors,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'floors': floors.map((f) => f.toJson()).toList(),
      'isActive': isActive,
    };
  }

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      id: json['id'] as String,
      name: json['name'] as String,
      floors: (json['floors'] as List)
          .map((f) => FloorModel.fromJson(f))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, floors, isActive];
}

class FloorModel extends Equatable {
  final String id;
  final String number;
  final List<RoomModel> rooms;

  const FloorModel({
    required this.id,
    required this.number,
    required this.rooms,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'rooms': rooms.map((r) => r.toJson()).toList(),
    };
  }

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'] as String,
      number: json['number'] as String,
      rooms: (json['rooms'] as List)
          .map((r) => RoomModel.fromJson(r))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, number, rooms];
}

class RoomModel extends Equatable {
  final String id;
  final String number;
  final String type;
  final bool isOccupied;

  const RoomModel({
    required this.id,
    required this.number,
    required this.type,
    this.isOccupied = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'type': type,
      'occupied': isOccupied,
    };
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      number: json['number'] as String,
      type: json['type'] as String,
      isOccupied: json['occupied'] as bool? ?? false,
    );
  }

  RoomModel copyWith({
    String? id,
    String? number,
    String? type,
    bool? isOccupied,
  }) {
    return RoomModel(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      isOccupied: isOccupied ?? this.isOccupied,
    );
  }

  @override
  List<Object?> get props => [id, number, type, isOccupied];
}

