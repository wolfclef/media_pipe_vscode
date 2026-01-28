import 'package:json_annotation/json_annotation.dart';

part 'face_data.g.dart';

@JsonSerializable()
class FaceData {
  final String userId;
  final String userName;
  final List<double> embeddings;
  final DateTime registeredAt;

  FaceData({
    required this.userId,
    required this.userName,
    required this.embeddings,
    required this.registeredAt,
  });

  factory FaceData.fromJson(Map<String, dynamic> json) =>
      _$FaceDataFromJson(json);

  Map<String, dynamic> toJson() => _$FaceDataToJson(this);
}

class MatchResult {
  final FaceData user;
  final double confidence;

  MatchResult({
    required this.user,
    required this.confidence,
  });

  double get confidencePercentage => confidence * 100;
}
