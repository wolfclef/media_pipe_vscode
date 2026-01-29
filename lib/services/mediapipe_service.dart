import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import '../utils/constants.dart';

// Access the global window object to get MediaPipe classes
@JS()
external JSObject get window;

// Dart wrapper classes
class FaceLandmark {
  final double x;
  final double y;
  final double z;

  FaceLandmark({required this.x, required this.y, required this.z});

  @override
  String toString() => 'FaceLandmark(x: $x, y: $y, z: $z)';
}

class MediaPipeService {
  JSObject? _faceLandmarker;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize MediaPipe Face Landmarker with retry logic
  Future<void> initialize() async {
    // Retry up to 10 times with 500ms intervals (total 5 seconds max)
    for (int attempt = 0; attempt < 10; attempt++) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        debugPrint('MediaPipe initialization attempt ${attempt + 1}/10');

        // Check if MediaPipe module is loaded
        final mediaPipeLoaded = window.getProperty('mediaPipeLoaded'.toJS);
        if (mediaPipeLoaded == null || mediaPipeLoaded.isUndefinedOrNull) {
          debugPrint('MediaPipe module still loading...');
          if (attempt == 9) {
            throw Exception('MediaPipe module failed to load after 5 seconds');
          }
          continue; // Retry
        }

        // Check if FilesetResolver is available
        final filesetResolverClass = window.getProperty('FilesetResolver'.toJS);
        if (filesetResolverClass == null || filesetResolverClass.isUndefinedOrNull) {
          debugPrint('FilesetResolver is undefined, retrying...');
          if (attempt == 9) {
            throw Exception('MediaPipe library not loaded. FilesetResolver is undefined.');
          }
          continue; // Retry
        }

        debugPrint('FilesetResolver found');

        final forVisionTasksMethod = (filesetResolverClass as JSObject).getProperty('forVisionTasks'.toJS);
        if (forVisionTasksMethod == null || forVisionTasksMethod.isUndefinedOrNull) {
          if (attempt == 9) {
            throw Exception('FilesetResolver.forVisionTasks is undefined.');
          }
          continue; // Retry
        }

        // Call forVisionTasks
        final filesetResolverPromise = (forVisionTasksMethod as JSFunction).callAsFunction(
          filesetResolverClass,
          FaceRecognitionConstants.mediapipeWasmPath.toJS,
        ) as JSPromise;
        final filesetResolver = await filesetResolverPromise.toDart as JSObject;

        // Check if FaceLandmarker is available
        final faceLandmarkerClass = window.getProperty('FaceLandmarker'.toJS);
        if (faceLandmarkerClass == null || faceLandmarkerClass.isUndefinedOrNull) {
          if (attempt == 9) {
            throw Exception('FaceLandmarker is undefined.');
          }
          continue; // Retry
        }

        final createFromOptionsMethod = (faceLandmarkerClass as JSObject).getProperty('createFromOptions'.toJS);
        if (createFromOptionsMethod == null || createFromOptionsMethod.isUndefinedOrNull) {
          if (attempt == 9) {
            throw Exception('FaceLandmarker.createFromOptions is undefined.');
          }
          continue; // Retry
        }

        // Create options object
        final options = <String, dynamic>{
          'baseOptions': {
            'modelAssetPath': FaceRecognitionConstants.mediapipeModelUrl,
          },
          'numFaces': 1,
          'minFaceDetectionConfidence': 0.5,
          'minFacePresenceConfidence': 0.5,
          'minTrackingConfidence': 0.5,
          'runningMode': 'VIDEO',
        }.jsify() as JSObject;

        // Call createFromOptions
        final faceLandmarkerPromise = (createFromOptionsMethod as JSFunction).callAsFunction(
          faceLandmarkerClass,
          filesetResolver,
          options,
        ) as JSPromise;
        _faceLandmarker = await faceLandmarkerPromise.toDart as JSObject;

        _isInitialized = true;
        return; // Success
      } catch (e) {
        if (attempt == 9) {
          throw Exception('Failed to initialize MediaPipe after 10 attempts: $e');
        }
        // Continue to next retry
      }
    }
  }

  /// Detect face landmarks from video element
  List<FaceLandmark>? detectFace(web.HTMLVideoElement video) {
    if (!_isInitialized || _faceLandmarker == null) {
      return null;
    }

    try {
      // Call detect method
      final detectMethod = _faceLandmarker!.getProperty('detect'.toJS) as JSFunction;
      final result = detectMethod.callAsFunction(_faceLandmarker, video) as JSObject;

      // Access faceLandmarks property
      final faceLandmarksArray = result.getProperty('faceLandmarks'.toJS);
      if (faceLandmarksArray.isUndefinedOrNull) {
        return null;
      }

      // Cast to JSObject once
      final faceLandmarksArrayObj = faceLandmarksArray as JSObject;

      // Get length of array
      final length = faceLandmarksArrayObj.getProperty('length'.toJS) as JSNumber;
      if (length.toDartInt == 0) {
        return null;
      }

      // Get first face landmarks
      final firstFace = faceLandmarksArrayObj.getProperty(0.toJS) as JSObject;
      final landmarksLength = (firstFace.getProperty('length'.toJS) as JSNumber).toDartInt;

      // Convert landmarks to Dart list
      final landmarks = <FaceLandmark>[];
      for (int i = 0; i < landmarksLength; i++) {
        final landmark = firstFace.getProperty(i.toJS) as JSObject;
        final x = (landmark.getProperty('x'.toJS) as JSNumber).toDartDouble;
        final y = (landmark.getProperty('y'.toJS) as JSNumber).toDartDouble;
        final z = (landmark.getProperty('z'.toJS) as JSNumber).toDartDouble;

        landmarks.add(FaceLandmark(x: x, y: y, z: z));
      }

      return landmarks;
    } catch (e) {
      // Silently fail if detection fails
      return null;
    }
  }

  /// Dispose of resources
  void dispose() {
    if (_faceLandmarker != null) {
      final closeMethod = _faceLandmarker!.getProperty('close'.toJS);
      if (!closeMethod.isUndefinedOrNull) {
        (closeMethod as JSFunction).callAsFunction(_faceLandmarker);
      }
      _faceLandmarker = null;
    }
    _isInitialized = false;
  }
}
