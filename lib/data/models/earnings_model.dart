import 'package:equatable/equatable.dart';

class EarningsData extends Equatable {
  final double totalEarnings;
  final int totalDeliveries;
  final double averageEarning;
  final double basePay;
  final double tips;
  final double bonuses;
  final DateTime date;

  const EarningsData({
    required this.totalEarnings,
    required this.totalDeliveries,
    required this.averageEarning,
    required this.basePay,
    required this.tips,
    required this.bonuses,
    required this.date,
  });

  EarningsData copyWith({
    double? totalEarnings,
    int? totalDeliveries,
    double? averageEarning,
    double? basePay,
    double? tips,
    double? bonuses,
    DateTime? date,
  }) {
    return EarningsData(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      averageEarning: averageEarning ?? this.averageEarning,
      basePay: basePay ?? this.basePay,
      tips: tips ?? this.tips,
      bonuses: bonuses ?? this.bonuses,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'totalDeliveries': totalDeliveries,
      'averageEarning': averageEarning,
      'basePay': basePay,
      'tips': tips,
      'bonuses': bonuses,
      'date': date.toIso8601String(),
    };
  }

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      averageEarning: (json['averageEarning'] ?? 0.0).toDouble(),
      basePay: (json['basePay'] ?? 0.0).toDouble(),
      tips: (json['tips'] ?? 0.0).toDouble(),
      bonuses: (json['bonuses'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [
    totalEarnings,
    totalDeliveries,
    averageEarning,
    basePay,
    tips,
    bonuses,
    date,
  ];
}

class GoalData extends Equatable {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final GoalType type;
  final bool isCompleted;

  const GoalData({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.type,
    required this.isCompleted,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  GoalData copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    GoalType? type,
    bool? isCompleted,
  }) {
    return GoalData(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    targetAmount,
    currentAmount,
    deadline,
    type,
    isCompleted,
  ];
}

enum GoalType {
  daily,
  weekly,
  monthly,
  custom,
}

extension GoalTypeExtension on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.daily:
        return 'Daily Goal';
      case GoalType.weekly:
        return 'Weekly Goal';
      case GoalType.monthly:
        return 'Monthly Goal';
      case GoalType.custom:
        return 'Custom Goal';
    }
  }
}