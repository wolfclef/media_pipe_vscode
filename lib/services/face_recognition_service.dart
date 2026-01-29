import 'package:flutter/foundation.dart';
import '../models/face_data.dart';
import '../services/face_storage_service.dart';
import '../services/mediapipe_service.dart';
import '../utils/constants.dart';
import '../utils/math_utils.dart';

class FaceRecognitionService {
  final FaceStorageService _storageService = FaceStorageService();

  /// Extract face embeddings from MediaPipe landmarks
  /// Converts 478 landmarks (x, y, z) into a normalized vector
  List<double> extractEmbeddings(List<FaceLandmark> landmarks) {
    // Flatten landmarks into a single vector
    final features = <double>[];

    // Calculate face center for normalization
    double centerX = 0, centerY = 0, centerZ = 0;
    for (final landmark in landmarks) {
      centerX += landmark.x;
      centerY += landmark.y;
      centerZ += landmark.z;
    }
    centerX /= landmarks.length;
    centerY /= landmarks.length;
    centerZ /= landmarks.length;

    // Extract features relative to face center (더 robust한 표현)
    for (final landmark in landmarks) {
      features.add(landmark.x - centerX);
      features.add(landmark.y - centerY);
      features.add(landmark.z - centerZ);
    }

    // Normalize the vector using L2 normalization
    final normalized = MathUtils.normalizeVector(features);

    debugPrint('📏 Embeddings - landmarks: ${landmarks.length}, features: ${features.length}, normalized magnitude: ${MathUtils.vectorMagnitude(normalized).toStringAsFixed(6)}');

    return normalized;
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
