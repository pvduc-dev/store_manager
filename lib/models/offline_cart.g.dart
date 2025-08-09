// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_cart.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineCartAdapter extends TypeAdapter<OfflineCart> {
  @override
  final int typeId = 0;

  @override
  OfflineCart read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineCart(
      items: (fields[0] as List).cast<OfflineCartItem>(),
      totalPrice: fields[1] as String,
      itemsCount: fields[2] as int,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineCart obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.items)
      ..writeByte(1)
      ..write(obj.totalPrice)
      ..writeByte(2)
      ..write(obj.itemsCount)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineCartAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OfflineCartItemAdapter extends TypeAdapter<OfflineCartItem> {
  @override
  final int typeId = 1;

  @override
  OfflineCartItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineCartItem(
      productId: fields[0] as int,
      name: fields[1] as String,
      price: fields[2] as String,
      quantity: fields[3] as int,
      imageUrl: fields[4] as String?,
      description: fields[5] as String?,
      addedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineCartItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineCartItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
