import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/face_data.dart';
import '../services/face_storage_service.dart';
import '../services/mediapipe_service.dart';
import '../utils/constants.dart';
import '../utils/math_utils.dart';

class FaceRecognitionService {
  final FaceStorageService _storageService = FaceStorageService();

  /// Extract face embeddings from MediaPipe landmarks
  /// Uses geometric distance ratios for pose-invariant features
  List<double> extractEmbeddings(List<FaceLandmark> landmarks) {
    // Key landmark indices from MediaPipe Face Mesh (478 points)
    // Reference: https://github.com/google/mediapipe/blob/master/mediapipe/modules/face_geometry/data/canonical_face_model_uv_visualization.png

    // Eyes
    final leftEyeOuter = landmarks[33];   // 왼쪽 눈 바깥쪽
    final leftEyeInner = landmarks[133];  // 왼쪽 눈 안쪽
    final rightEyeInner = landmarks[362]; // 오른쪽 눈 안쪽
    final rightEyeOuter = landmarks[263]; // 오른쪽 눈 바깥쪽
    final leftEyeTop = landmarks[159];    // 왼쪽 눈 위
    final leftEyeBottom = landmarks[145]; // 왼쪽 눈 아래
    final rightEyeTop = landmarks[386];   // 오른쪽 눈 위
    final rightEyeBottom = landmarks[374]; // 오른쪽 눈 아래

    // Nose
    final noseTip = landmarks[1];         // 코끝
    final noseBottom = landmarks[2];      // 코 아래
    final noseLeft = landmarks[98];       // 코 왼쪽
    final noseRight = landmarks[327];     // 코 오른쪽

    // Mouth
    final mouthLeft = landmarks[61];      // 입 왼쪽
    final mouthRight = landmarks[291];    // 입 오른쪽
    final mouthTop = landmarks[13];       // 입 위
    final mouthBottom = landmarks[14];    // 입 아래

    // Face contour
    final chinBottom = landmarks[152];    // 턱
    final foreheadCenter = landmarks[10]; // 이마
    final leftCheek = landmarks[234];     // 왼쪽 볼
    final rightCheek = landmarks[454];    // 오른쪽 볼

    // Calculate key distances
    final eyeDistance = _distance3D(leftEyeInner, rightEyeInner);

    // Normalize all measurements by eye distance (most stable reference)
    final features = <double>[
      // Eye measurements
      _distance3D(leftEyeOuter, leftEyeInner) / eyeDistance,
      _distance3D(rightEyeInner, rightEyeOuter) / eyeDistance,
      _distance3D(leftEyeTop, leftEyeBottom) / eyeDistance,
      _distance3D(rightEyeTop, rightEyeBottom) / eyeDistance,

      // Nose measurements
      _distance3D(noseTip, noseBottom) / eyeDistance,
      _distance3D(noseLeft, noseRight) / eyeDistance,
      _distance3D(noseTip, leftEyeInner) / eyeDistance,
      _distance3D(noseTip, rightEyeInner) / eyeDistance,

      // Mouth measurements
      _distance3D(mouthLeft, mouthRight) / eyeDistance,
      _distance3D(mouthTop, mouthBottom) / eyeDistance,

      // Nose to mouth distance
      _distance3D(noseTip, mouthTop) / eyeDistance,
      _distance3D(noseBottom, mouthTop) / eyeDistance,

      // Face proportions
      _distance3D(foreheadCenter, chinBottom) / eyeDistance,
      _distance3D(leftCheek, rightCheek) / eyeDistance,

      // Eye to mouth distances
      _distance3D(leftEyeInner, mouthLeft) / eyeDistance,
      _distance3D(rightEyeInner, mouthRight) / eyeDistance,

      // Vertical proportions
      _distance3D(foreheadCenter, noseTip) / eyeDistance,
      _distance3D(noseTip, chinBottom) / eyeDistance,
      _distance3D(leftEyeInner, chinBottom) / eyeDistance,
      _distance3D(rightEyeInner, chinBottom) / eyeDistance,

      // Additional facial ratios
      _distance3D(leftEyeOuter, mouthLeft) / eyeDistance,
      _distance3D(rightEyeOuter, mouthRight) / eyeDistance,
      _distance3D(noseTip, leftCheek) / eyeDistance,
      _distance3D(noseTip, rightCheek) / eyeDistance,
    ];

    // Normalize the feature vector
    final normalized = MathUtils.normalizeVector(features);

    debugPrint('📏 Embeddings - ${features.length} geometric ratios, normalized magnitude: ${MathUtils.vectorMagnitude(normalized).toStringAsFixed(6)}');

    return normalized;
  }

  /// Calculate 3D Euclidean distance between two landmarks
  double _distance3D(FaceLandmark a, FaceLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final dz = a.z - b.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Recognize a face from landmarks
  /// Returns MatchResult if a match is found above threshold, null otherwise
  Future<MatchResult?> recognizeFace(List<FaceLandmark> landmarks) async {
    // Extract embeddings from detected face
    final embeddings = extractEmbeddings(landmarks);

    debugPrint('🔍 Recognizing face - embeddings length: ${embeddings.length}');
    debugPrint('   Current embedding sample: [${embeddings.take(5).map((e) => e.toStringAsFixed(4)).join(", ")}...]');

    // Get all stored faces
    final storedFaces = await _storageService.getAllFaces();

    if (storedFaces.isEmpty) {
      debugPrint('❌ No stored faces found');
      return null;
    }

    debugPrint('📊 Comparing with ${storedFaces.length} stored face(s)');

    // Find best match
    double bestScore = 0.0;
    FaceData? bestMatch;

    for (final storedFace in storedFaces) {
      debugPrint('   Stored ${storedFace.userName} embedding sample: [${storedFace.embeddings.take(5).map((e) => e.toStringAsFixed(4)).join(", ")}...]');

      // Calculate cosine similarity
      final similarity = MathUtils.cosineSimilarity(
        embeddings,
        storedFace.embeddings,
      );

      debugPrint('   ${storedFace.userName}: ${(similarity * 100).toStringAsFixed(2)}%');

      if (similarity > bestScore) {
        bestScore = similarity;
        bestMatch = storedFace;
      }
    }

    debugPrint('✨ Best match: ${bestMatch?.userName} with ${(bestScore * 100).toStringAsFixed(2)}% (threshold: ${(FaceRecognitionConstants.matchThreshold * 100).toStringAsFixed(0)}%)');

    // Return match only if above threshold
    if (bestScore >= FaceRecognitionConstants.matchThreshold) {
      return MatchResult(
        user: bestMatch!,
        confidence: bestScore,
      );
    }

    return null;
  }

  /// Register a new face
  Future<void> registerFace({
    required String userId,
    required String userName,
    required List<FaceLandmark> landmarks,
  }) async {
    // Extract embeddings
    final embeddings = extractEmbeddings(landmarks);

    debugPrint('💾 Registering $userName - embedding sample: [${embeddings.take(5).map((e) => e.toStringAsFixed(4)).join(", ")}...]');

    // Create face data
    final faceData = FaceData(
      userId: userId,
      userName: userName,
      embeddings: embeddings,
      registeredAt: DateTime.now(),
    );

    // Save to storage
    await _storageService.saveFaceData(faceData);
  }

  /// Get all registered users
  Future<List<FaceData>> getAllRegisteredUsers() async {
    return await _storageService.getAllFaces();
  }

  /// Delete a registered user
  Future<void> deleteUser(String userId) async {
    await _storageService.deleteFaceData(userId);
  }

  /// Get count of registered users
  Future<int> getRegisteredUserCount() async {
    return await _storageService.getFaceCount();
  }

  /// Calculate similarity between two faces
  /// Returns a value between 0 and 1, where 1 is identical
  double calculateSimilarity(
    List<FaceLandmark> landmarks1,
    List<FaceLandmark> landmarks2,
  ) {
    final embeddings1 = extractEmbeddings(landmarks1);
    final embeddings2 = extractEmbeddings(landmarks2);
    return MathUtils.cosineSimilarity(embeddings1, embeddings2);
  }
}
