class FaceRecognitionConstants {
  // MediaPipe configuration
  static const String mediapipeModelUrl =
      'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/latest/face_landmarker.task';

  static const String mediapipeWasmPath =
      'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@latest/wasm';

  // Recognition thresholds
  static const double matchThreshold = 0.85; // 85% similarity required
  static const double highConfidence = 0.95; // 95%+ = excellent match

  // Camera settings
  static const int cameraWidth = 640;
  static const int cameraHeight = 480;

  // Processing settings
  static const int detectionIntervalMs = 100; // Process 10 frames/sec

  // Storage keys
  static const String keyPrefix = 'face_data_';
  static const String userListKey = 'registered_users';
}
