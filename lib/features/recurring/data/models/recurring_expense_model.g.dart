// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringExpenseModelAdapter extends TypeAdapter<RecurringExpenseModel> {
  @override
  final int typeId = 5;

  @override
  RecurringExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringExpenseModel(
      id: fields[0] as String,
      title: fields[1] as String?,
      merchant: fields[2] as String?,
      amount: fields[3] as double,
      currency: fields[4] as String,
      originalAmount: fields[5] as double?,
      exchangeRate: fields[6] as double?,
      categoryId: fields[7] as String,
      paymentMethod: fields[8] as String?,
      note: fields[9] as String?,
      frequency: fields[10] as String,
      interval: fields[11] as int,
      startDate: fields[12] as DateTime,
      endDate: fields[13] as DateTime?,
      generatedCount: fields[14] as int,
      isActive: fields[15] as bool,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      taxTag: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringExpenseModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.merchant)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.originalAmount)
      ..writeByte(6)
      ..write(obj.exchangeRate)
      ..writeByte(7)
      ..write(obj.categoryId)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.frequency)
      ..writeByte(11)
      ..write(obj.interval)
      ..writeByte(12)
      ..write(obj.startDate)
      ..writeByte(13)
      ..write(obj.endDate)
      ..writeByte(14)
      ..write(obj.generatedCount)
      ..writeByte(15)
      ..write(obj.isActive)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.taxTag);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
