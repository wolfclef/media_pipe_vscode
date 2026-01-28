import '../models/face_data.dart';
import '../services/face_storage_service.dart';
import '../services/mediapipe_service.dart';
import '../utils/constants.dart';
import '../utils/math_utils.dart';

class FaceRecognitionService {
  final FaceStorageService _storageService = FaceStorageService();

  /// Extract face embeddings from MediaPipe landmarks
  /// Converts 478 landmarks (x, y, z) into a 1434-dimensional normalized vector
  List<double> extractEmbeddings(List<FaceLandmark> landmarks) {
    // Flatten landmarks into a single vector
    final features = <double>[];
    for (final landmark in landmarks) {
      features.add(landmark.x);
      features.add(landmark.y);
      features.add(landmark.z);
    }

    // Normalize the vector using L2 normalization
    return MathUtils.normalizeVector(features);
  }

  /// Recognize a face from landmarks
  /// Returns MatchResult if a match is found above threshold, null otherwise
  Future<MatchResult?> recognizeFace(List<FaceLandmark> landmarks) async {
    // Extract embeddings from detected face
    final embeddings = extractEmbeddings(landmarks);

    // Get all stored faces
    final storedFaces = await _storageService.getAllFaces();

    if (storedFaces.isEmpty) {
      return null;
    }

    // Find best match
    double bestScore = 0.0;
    FaceData? bestMatch;

    for (final storedFace in storedFaces) {
      // Calculate cosine similarity
      final similarity = MathUtils.cosineSimilarity(
        embeddings,
        storedFace.embeddings,
      );

      if (similarity > bestScore) {
        bestScore = similarity;
        bestMatch = storedFace;
      }
    }

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
