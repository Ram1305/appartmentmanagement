import 'package:equatable/equatable.dart';

enum VisitorType {
  cabTaxi,
  family,
  deliveryBoy,
  guest,
  maid,
  electrician,
  plumber,
  courier,
  maintenance,
  officialVisitor,
  emergency,
  other,
}

/// Display labels for visitor type grid; order matches [VisitorType] excluding [VisitorType.other].
const List<String> visitorTypeDisplayNames = [
  'Cab / Taxi',
  'Family',
  'Delivery Boy',
  'Guest',
  'Maid',
  'Electrician',
  'Plumber',
  'Courier',
  'Maintenance',
  'Official Visitor',
  'Emergency',
];

extension VisitorTypeX on VisitorType {
  String get displayName {
    const names = visitorTypeDisplayNames;
    final index = indexOf(this);
    if (index >= 0 && index < names.length) return names[index];
    return name;
  }

  static int indexOf(VisitorType type) {
    final list = VisitorType.values.where((e) => e != VisitorType.other).toList();
    final i = list.indexOf(type);
    return i >= 0 ? i : -1;
  }

  static VisitorType? fromDisplayName(String displayName) {
    final lower = displayName.trim().toLowerCase();
    for (int i = 0; i < visitorTypeDisplayNames.length; i++) {
      if (visitorTypeDisplayNames[i].toLowerCase() == lower) {
        return VisitorType.values[i];
      }
    }
    return null;
  }
}

enum VisitorCategory {
  relative,
  outsider,
}

enum RelativeType {
  father,
  mother,
  brother,
  sister,
  spouse,
  son,
  daughter,
  other,
}

class VisitorModel extends Equatable {
  final String id;
  final String name;
  final String mobileNumber;
  final String? image;
  final VisitorType type;
  final VisitorCategory category;
  final RelativeType? relativeType;
  final String? reasonForVisit;
  final String? vehicleNumber;
  final String block;
  final String homeNumber;
  final DateTime visitTime;
  final String? otp;
  final String? qrCode;
  final bool isRegistered;

  const VisitorModel({
    required this.id,
    required this.name,
    required this.mobileNumber,
    this.image,
    required this.type,
    required this.category,
    this.relativeType,
    this.reasonForVisit,
    this.vehicleNumber,
    required this.block,
    required this.homeNumber,
    required this.visitTime,
    this.otp,
    this.qrCode,
    this.isRegistered = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'image': image,
      'type': type.name,
      'category': category.name,
      'relativeType': relativeType?.name,
      'reasonForVisit': reasonForVisit,
      'vehicleNumber': vehicleNumber,
      'block': block,
      'homeNumber': homeNumber,
      'visitTime': visitTime.toIso8601String(),
      'otp': otp,
      'qrCode': qrCode,
      'isRegistered': isRegistered,
    };
  }

  static VisitorType _parseVisitorType(dynamic value) {
    if (value == null || value is! String) return VisitorType.other;
    final name = value.toString().trim();
    for (final e in VisitorType.values) {
      if (e.name == name) return e;
    }
    return VisitorType.other;
  }

  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    return VisitorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      mobileNumber: json['mobileNumber'] as String,
      image: json['image'] as String?,
      type: _parseVisitorType(json['type']),
      category: json['category'] != null
          ? VisitorCategory.values.firstWhere(
              (e) => e.name == json['category'],
              orElse: () => VisitorCategory.outsider,
            )
          : VisitorCategory.outsider,
      relativeType: json['relativeType'] != null
          ? RelativeType.values.firstWhere(
              (e) => e.name == json['relativeType'],
              orElse: () => RelativeType.other,
            )
          : null,
      reasonForVisit: json['reasonForVisit'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      block: json['block'] as String,
      homeNumber: json['homeNumber'] as String,
      visitTime: DateTime.parse(json['visitTime'] as String),
      otp: json['otp'] as String?,
      qrCode: json['qrCode'] as String?,
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
        category,
        relativeType,
        reasonForVisit,
        vehicleNumber,
        block,
        homeNumber,
        visitTime,
        otp,
        qrCode,
        isRegistered,
      ];
}

