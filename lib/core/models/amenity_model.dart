import 'package:equatable/equatable.dart';

class AmenityModel extends Equatable {
  final String id;
  final String name;
  final bool isEnabled;
  final int displayOrder;

  const AmenityModel({
    required this.id,
    required this.name,
    this.isEnabled = true,
    this.displayOrder = 0,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    return AmenityModel(
      id: id,
      name: json['name'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isEnabled': isEnabled,
      'displayOrder': displayOrder,
    };
  }

  AmenityModel copyWith({
    String? id,
    String? name,
    bool? isEnabled,
    int? displayOrder,
  }) {
    return AmenityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  List<Object?> get props => [id, name, isEnabled, displayOrder];
}
