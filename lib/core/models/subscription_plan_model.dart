import 'package:equatable/equatable.dart';

class SubscriptionPlanModel extends Equatable {
  final String id;
  final String name;
  final int daysValidity;
  final double amount;
  final String description;
  final bool isActive;
  final String? color;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.daysValidity,
    required this.amount,
    this.description = '',
    this.isActive = true,
    this.color,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final amount = json['amount'];
    return SubscriptionPlanModel(
      id: id,
      name: json['name'] as String? ?? '',
      daysValidity: (json['daysValidity'] is int)
          ? json['daysValidity'] as int
          : (json['daysValidity'] as num?)?.toInt() ?? 0,
      amount: amount is int ? amount.toDouble() : (amount as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      color: json['color'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, daysValidity, amount, description, isActive, color];
}
