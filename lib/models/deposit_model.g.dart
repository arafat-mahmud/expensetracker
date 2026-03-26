// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deposit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DepositProfileAdapter extends TypeAdapter<DepositProfile> {
  @override
  final int typeId = 1;

  @override
  DepositProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DepositProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmount: fields[2] as double,
      deadline: fields[3] as DateTime,
      createdDate: fields[4] as DateTime,
      note: fields[5] as String,
      isCompleted: fields[6] as bool,
      completedDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DepositProfile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.deadline)
      ..writeByte(4)
      ..write(obj.createdDate)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.completedDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepositProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DepositTransactionAdapter extends TypeAdapter<DepositTransaction> {
  @override
  final int typeId = 2;

  @override
  DepositTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DepositTransaction(
      id: fields[0] as String,
      profileId: fields[1] as String,
      amount: fields[2] as double,
      type: fields[3] as String,
      date: fields[4] as DateTime,
      note: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DepositTransaction obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.profileId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepositTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
