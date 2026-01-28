// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'face_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaceData _$FaceDataFromJson(Map<String, dynamic> json) => FaceData(
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  embeddings: (json['embeddings'] as List<dynamic>)
      .map((e) => (e as num).toDouble())
      .toList(),
  registeredAt: DateTime.parse(json['registeredAt'] as String),
);

Map<String, dynamic> _$FaceDataToJson(FaceData instance) => <String, dynamic>{
  'userId': instance.userId,
  'userName': instance.userName,
  'embeddings': instance.embeddings,
  'registeredAt': instance.registeredAt.toIso8601String(),
};
