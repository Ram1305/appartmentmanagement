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
      'block': block,
      'homeNumber': homeNumber,
      'visitTime': visitTime.toIso8601String(),
      'otp': otp,
      'qrCode': qrCode,
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
        block,
        homeNumber,
        visitTime,
        otp,
        qrCode,
        isRegistered,
      ];
}

