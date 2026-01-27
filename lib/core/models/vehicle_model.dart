import 'package:equatable/equatable.dart';

enum VehicleType {
  twoWheeler,
  fourWheeler,
  other,
}

class VehicleModel extends Equatable {
  final String id;
  final String vehicleType;
  final String vehicleNumber;
  final String? imageUrl;

  const VehicleModel({
    required this.id,
    required this.vehicleType,
    required this.vehicleNumber,
    this.imageUrl,
  });

  String get displayType {
    switch (vehicleType) {
      case 'twoWheeler':
        return 'Two wheeler';
      case 'fourWheeler':
        return 'Four wheeler';
      default:
        return 'Other';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'image': imageUrl,
    };
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    return VehicleModel(
      id: id,
      vehicleType: json['vehicleType'] as String? ?? 'other',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      imageUrl: json['image'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, vehicleType, vehicleNumber, imageUrl];
}
