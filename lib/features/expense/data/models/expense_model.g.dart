// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 0;

  @override
  ExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      currency: fields[2] as String,
      categoryId: fields[3] as String,
      note: fields[4] as String?,
      title: fields[11] as String?,
      paymentMethod: fields[12] as String?,
      serverId: fields[13] as String?,
      date: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      lastSyncedAt: fields[14] as DateTime?,
      merchant: fields[15] as String?,
      originalAmount: fields[16] as double?,
      exchangeRate: fields[17] as double?,
      recurringId: fields[18] as String?,
      taxTag: fields[19] as String?,
      eventId: fields[20] as String?,
      version: fields[8] as int,
      syncStatus: fields[9] as String,
      isDeleted: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.currency)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.title)
      ..writeByte(12)
      ..write(obj.paymentMethod)
      ..writeByte(13)
      ..write(obj.serverId)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.lastSyncedAt)
      ..writeByte(15)
      ..write(obj.merchant)
      ..writeByte(16)
      ..write(obj.originalAmount)
      ..writeByte(17)
      ..write(obj.exchangeRate)
      ..writeByte(18)
      ..write(obj.recurringId)
      ..writeByte(19)
      ..write(obj.taxTag)
      ..writeByte(20)
      ..write(obj.eventId)
      ..writeByte(8)
      ..write(obj.version)
      ..writeByte(9)
      ..write(obj.syncStatus)
      ..writeByte(10)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
