import 'package:hive/hive.dart';

part 'budget_entity.g.dart';

@HiveType(typeId: 2)
enum BudgetPeriod {
  @HiveField(0)
  monthly,
  @HiveField(1)
  quarterly,
  @HiveField(2)
  yearly,
  @HiveField(3)
  noLimit,
}

class BudgetEntity {
  final String categoryId;
  final double limit;
  final BudgetPeriod period;

  const BudgetEntity({
    required this.categoryId,
    required this.limit,
    this.period = BudgetPeriod.monthly,
  });
}
