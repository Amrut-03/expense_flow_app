// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'embedding_chunk_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmbeddingChunkModelAdapter extends TypeAdapter<EmbeddingChunkModel> {
  @override
  final int typeId = 3;

  @override
  EmbeddingChunkModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmbeddingChunkModel(
      id: fields[0] as String,
      chunkType: fields[1] as String,
      text: fields[2] as String,
      embedding: (fields[3] as List).cast<double>(),
      sourceId: fields[4] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      needsEmbedding: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EmbeddingChunkModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chunkType)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.embedding)
      ..writeByte(4)
      ..write(obj.sourceId)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.needsEmbedding);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmbeddingChunkModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
