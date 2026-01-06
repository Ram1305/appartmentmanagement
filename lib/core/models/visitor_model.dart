import 'package:equatable/equatable.dart';

enum VisitorType {
  swiggy,
  zomato,
  zepto,
  amazon,
  delivery,
  guest,
  service,
  other,
}

class VisitorModel extends Equatable {
  final String id;
  final String name;
  final String mobileNumber;
  final String? image;
  final VisitorType type;
  final String block;
  final String homeNumber;
  final DateTime visitTime;
  final String? otp;
  final bool isRegistered;

  const VisitorModel({
    required this.id,
    required this.name,
    required this.mobileNumber,
    this.image,
    required this.type,
    required this.block,
    required this.homeNumber,
    required this.visitTime,
    this.otp,
    this.isRegistered = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'image': image,
      'type': type.name,
      'block': block,
      'homeNumber': homeNumber,
      'visitTime': visitTime.toIso8601String(),
      'otp': otp,
      'isRegistered': isRegistered,
    };
  }

  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    return VisitorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      mobileNumber: json['mobileNumber'] as String,
      image: json['image'] as String?,
      type: VisitorType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VisitorType.other,
      ),
      block: json['block'] as String,
      homeNumber: json['homeNumber'] as String,
      visitTime: DateTime.parse(json['visitTime'] as String),
      otp: json['otp'] as String?,
      isRegistered: json['isRegistered'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        mobileNumber,
        image,
        type,
        block,
        homeNumber,
        visitTime,
        otp,
        isRegistered,
      ];
}

