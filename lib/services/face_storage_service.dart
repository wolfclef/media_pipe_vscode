import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/face_data.dart';
import '../utils/constants.dart';

class FaceStorageService {
  /// Save face data to local storage
  Future<void> saveFaceData(FaceData faceData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save face data
    await prefs.setString(
      '${FaceRecognitionConstants.keyPrefix}${faceData.userId}',
      jsonEncode(faceData.toJson()),
    );

    // Update user list
    List<String> users =
        prefs.getStringList(FaceRecognitionConstants.userListKey) ?? [];
    if (!users.contains(faceData.userId)) {
      users.add(faceData.userId);
      await prefs.setStringList(FaceRecognitionConstants.userListKey, users);
    }
  }

  /// Get all registered faces
  Future<List<FaceData>> getAllFaces() async {
    final prefs = await SharedPreferences.getInstance();
    final userIds =
        prefs.getStringList(FaceRecognitionConstants.userListKey) ?? [];

    final faces = <FaceData>[];
    for (final userId in userIds) {
      final jsonStr =
          prefs.getString('${FaceRecognitionConstants.keyPrefix}$userId');
      if (jsonStr != null) {
        try {
          final faceData = FaceData.fromJson(jsonDecode(jsonStr));
          faces.add(faceData);
        } catch (e) {
          // Skip invalid data
        }
      }
    }

    return faces;
  }

  /// Get face data by user ID
  Future<FaceData?> getFaceData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr =
        prefs.getString('${FaceRecognitionConstants.keyPrefix}$userId');

    if (jsonStr == null) {
      return null;
    }

    try {
      return FaceData.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  /// Delete face data by user ID
  Future<void> deleteFaceData(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove face data
    await prefs.remove('${FaceRecognitionConstants.keyPrefix}$userId');

    // Update user list
    List<String> users =
        prefs.getStringList(FaceRecognitionConstants.userListKey) ?? [];
    users.remove(userId);
    await prefs.setStringList(FaceRecognitionConstants.userListKey, users);
  }

  /// Delete all face data
  Future<void> deleteAllFaces() async {
    final prefs = await SharedPreferences.getInstance();
    final userIds =
        prefs.getStringList(FaceRecognitionConstants.userListKey) ?? [];

    // Remove all face data
    for (final userId in userIds) {
      await prefs.remove('${FaceRecognitionConstants.keyPrefix}$userId');
    }

    // Clear user list
    await prefs.remove(FaceRecognitionConstants.userListKey);
  }

  /// Get count of registered faces
  Future<int> getFaceCount() async {
    final prefs = await SharedPreferences.getInstance();
    final userIds =
        prefs.getStringList(FaceRecognitionConstants.userListKey) ?? [];
    return userIds.length;
  }
}
