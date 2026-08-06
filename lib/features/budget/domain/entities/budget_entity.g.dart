// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetPeriodAdapter extends TypeAdapter<BudgetPeriod> {
  @override
  final int typeId = 2;

  @override
  BudgetPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetPeriod.monthly;
      case 1:
        return BudgetPeriod.quarterly;
      case 2:
        return BudgetPeriod.yearly;
      case 3:
        return BudgetPeriod.noLimit;
      default:
        return BudgetPeriod.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetPeriod obj) {
    switch (obj) {
      case BudgetPeriod.monthly:
        writer.writeByte(0);
        break;
      case BudgetPeriod.quarterly:
        writer.writeByte(1);
        break;
      case BudgetPeriod.yearly:
        writer.writeByte(2);
        break;
      case BudgetPeriod.noLimit:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
