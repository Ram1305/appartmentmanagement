import 'package:equatable/equatable.dart';

enum ComplaintType {
  plumbing,
  electrical,
  cleaning,
  maintenance,
  security,
  other,
}

enum ComplaintStatus {
  pending,
  inProgress,
  resolved,
  rejected,
}

class ComplaintModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final ComplaintType type;
  final String description;
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedTo;
  final String? remarks;

  const ComplaintModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'remarks': remarks,
    };
  }

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      type: ComplaintType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ComplaintType.other,
      ),
      description: json['description'] as String,
      status: ComplaintStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ComplaintStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      assignedTo: json['assignedTo'] as String?,
      remarks: json['remarks'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        type,
        description,
        status,
        createdAt,
        updatedAt,
        assignedTo,
        remarks,
      ];
}

