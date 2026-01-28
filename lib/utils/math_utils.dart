import 'dart:math';

class MathUtils {
  /// Calculate cosine similarity between two vectors
  /// Returns a value between -1 and 1, where 1 means identical vectors
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    double dotProduct = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
    }

    return dotProduct;
  }

  /// Normalize a vector using L2 normalization
  /// Returns a vector with magnitude 1.0
  static List<double> normalizeVector(List<double> vector) {
    double magnitude = sqrt(
      vector.fold<double>(0.0, (sum, val) => sum + val * val),
    );

    if (magnitude == 0) {
      return vector;
    }

    return vector.map((v) => v / magnitude).toList();
  }

  /// Calculate the magnitude (length) of a vector
  static double vectorMagnitude(List<double> vector) {
    return sqrt(
      vector.fold<double>(0.0, (sum, val) => sum + val * val),
    );
  }

  /// Calculate Euclidean distance between two vectors
  static double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    double sumSquaredDiff = 0.0;
    for (int i = 0; i < a.length; i++) {
      double diff = a[i] - b[i];
      sumSquaredDiff += diff * diff;
    }

    return sqrt(sumSquaredDiff);
  }
}
