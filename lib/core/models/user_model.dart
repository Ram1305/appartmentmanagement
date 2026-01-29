import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum UserType { admin, manager, user, security }

enum AccountStatus { pending, approved, rejected }

enum FamilyType { family, bachelor }

enum Gender { male, female, other }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String username;
  final String email;
  final String mobileNumber;
  final String? secondaryMobileNumber;
  final Gender? gender;
  final UserType userType;
  final AccountStatus status;
  final String? profilePic;
  final String? address;
  final String? aadhaarCard;
  final String? aadhaarCardFrontImage;
  final String? aadhaarCardBackImage;
  final String? panCard;
  final String? panCardImage;
  final FamilyType? familyType;
  final int? totalOccupants;
  final String? block;
  final String? floor;
  final String? roomNumber;
  final bool isActive;
  final bool? subscriptionStatus;
  final DateTime? subscriptionEndsAt;
  final int? daysLeft;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobileNumber,
    required this.userType,
    required this.status,
    this.secondaryMobileNumber,
    this.gender,
    this.profilePic,
    this.address,
    this.aadhaarCard,
    this.aadhaarCardFrontImage,
    this.aadhaarCardBackImage,
    this.panCard,
    this.panCardImage,
    this.familyType,
    this.totalOccupants,
    this.block,
    this.floor,
    this.roomNumber,
    this.isActive = true,
    this.subscriptionStatus,
    this.subscriptionEndsAt,
    this.daysLeft,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? mobileNumber,
    String? secondaryMobileNumber,
    Gender? gender,
    UserType? userType,
    AccountStatus? status,
    String? profilePic,
    String? address,
    String? aadhaarCard,
    String? aadhaarCardFrontImage,
    String? aadhaarCardBackImage,
    String? panCard,
    String? panCardImage,
    FamilyType? familyType,
    int? totalOccupants,
    String? block,
    String? floor,
    String? roomNumber,
    bool? isActive,
    bool? subscriptionStatus,
    DateTime? subscriptionEndsAt,
    int? daysLeft,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      secondaryMobileNumber:
          secondaryMobileNumber ?? this.secondaryMobileNumber,
      gender: gender ?? this.gender,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      profilePic: profilePic ?? this.profilePic,
      address: address ?? this.address,
      aadhaarCard: aadhaarCard ?? this.aadhaarCard,
      aadhaarCardFrontImage:
          aadhaarCardFrontImage ?? this.aadhaarCardFrontImage,
      aadhaarCardBackImage: aadhaarCardBackImage ?? this.aadhaarCardBackImage,
      panCard: panCard ?? this.panCard,
      panCardImage: panCardImage ?? this.panCardImage,
      familyType: familyType ?? this.familyType,
      totalOccupants: totalOccupants ?? this.totalOccupants,
      block: block ?? this.block,
      floor: floor ?? this.floor,
      roomNumber: roomNumber ?? this.roomNumber,
      isActive: isActive ?? this.isActive,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionEndsAt: subscriptionEndsAt ?? this.subscriptionEndsAt,
      daysLeft: daysLeft ?? this.daysLeft,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'mobileNumber': mobileNumber,
      'secondaryMobileNumber': secondaryMobileNumber,
      'gender': gender?.name,
      'userType': userType.name,
      'status': status.name,
      'profilePic': profilePic,
      'address': address,
      'aadhaarCard': aadhaarCard,
      'aadhaarCardFrontImage': aadhaarCardFrontImage,
      'aadhaarCardBackImage': aadhaarCardBackImage,
      'panCard': panCard,
      'panCardImage': panCardImage,
      'familyType': familyType?.name,
      'totalOccupants': totalOccupants,
      'block': block,
      'floor': floor,
      'roomNumber': roomNumber,
      'isActive': isActive,
      if (subscriptionStatus != null) 'subscriptionStatus': subscriptionStatus,
      if (subscriptionEndsAt != null) 'subscriptionEndsAt': subscriptionEndsAt?.toIso8601String(),
      if (daysLeft != null) 'daysLeft': daysLeft,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB _id field
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    return UserModel(
      id: id,
      name: json['name'] as String,
      username: json['username'] as String? ?? json['name'] as String,
      email: json['email'] as String,
      mobileNumber: json['mobileNumber'] as String,
      secondaryMobileNumber: json['secondaryMobileNumber'] as String?,
      gender: json['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.name == json['gender'],
              orElse: () => Gender.male,
            )
          : null,
      userType: () {
        final userTypeStr = json['userType']?.toString().toLowerCase().trim();
        debugPrint('=== PARSING USERTYPE ===');
        debugPrint('Raw userType from JSON: ${json['userType']}');
        debugPrint('Normalized userType: "$userTypeStr"');
        debugPrint(
            'Available UserType values: ${UserType.values.map((e) => e.name).toList()}');

        if (userTypeStr == null || userTypeStr.isEmpty) {
          debugPrint(
              'WARNING: userType is null or empty, defaulting to UserType.user');
          return UserType.user;
        }

        try {
          final parsed = UserType.values.firstWhere(
            (e) => e.name.toLowerCase() == userTypeStr,
            orElse: () {
              debugPrint(
                  'WARNING: userType "$userTypeStr" not found in enum, defaulting to UserType.user');
              debugPrint(
                  'Trying to match: "$userTypeStr" against: ${UserType.values.map((e) => e.name).toList()}');
              return UserType.user;
            },
          );
          debugPrint('✓ Successfully parsed UserType: $parsed (${parsed.name})');
          return parsed;
        } catch (e) {
          debugPrint('ERROR parsing userType: $e');
          return UserType.user;
        }
      }(),
      status: AccountStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AccountStatus.pending,
      ),
      profilePic: json['profilePic'] as String?,
      address: json['address'] as String?,
      aadhaarCard: json['aadhaarCard'] as String?,
      aadhaarCardFrontImage: json['aadhaarCardFrontImage'] as String?,
      aadhaarCardBackImage: json['aadhaarCardBackImage'] as String?,
      panCard: json['panCard'] as String?,
      panCardImage: json['panCardImage'] as String?,
      familyType: json['familyType'] != null
          ? FamilyType.values.firstWhere(
              (e) => e.name == json['familyType'],
              orElse: () => FamilyType.family,
            )
          : null,
      totalOccupants: json['totalOccupants'] as int?,
      block: json['block'] as String?,
      floor: json['floor'] as String?,
      roomNumber: json['roomNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      subscriptionStatus: json['subscriptionStatus'] as bool?,
      subscriptionEndsAt: json['subscriptionEndsAt'] != null
          ? DateTime.tryParse(json['subscriptionEndsAt'].toString())
          : null,
      daysLeft: json['daysLeft'] is int
          ? json['daysLeft'] as int
          : (json['daysLeft'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        email,
        mobileNumber,
        secondaryMobileNumber,
        gender,
        userType,
        status,
        profilePic,
        address,
        aadhaarCard,
        aadhaarCardFrontImage,
        aadhaarCardBackImage,
        panCard,
        panCardImage,
        familyType,
        totalOccupants,
        block,
        floor,
        roomNumber,
        isActive,
        subscriptionStatus,
        subscriptionEndsAt,
        daysLeft,
      ];
}
