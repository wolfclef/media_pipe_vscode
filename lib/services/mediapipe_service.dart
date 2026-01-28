import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;
import '../utils/constants.dart';

// JS Interop bindings for MediaPipe
@JS('FaceLandmarker')
@staticInterop
class JSFaceLandmarker {}

extension JSFaceLandmarkerExtension on JSFaceLandmarker {
  external JSObject detect(web.HTMLVideoElement video);
  external void close();
}

// Static constructor method for FaceLandmarker
@JS('FaceLandmarker.createFromOptions')
external JSPromise _createFaceLandmarkerFromOptions(
  JSObject visionFilesetResolver,
  JSObject options,
);

@JS('FilesetResolver')
@staticInterop
class JSFilesetResolver {}

// Static method for FilesetResolver
@JS('FilesetResolver.forVisionTasks')
external JSPromise _filesetResolverForVisionTasks(JSString wasmPath);

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
  JSFaceLandmarker? _faceLandmarker;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize MediaPipe Face Landmarker
  Future<void> initialize() async {
    try {
      // Load WASM files
      final filesetResolver = await _filesetResolverForVisionTasks(
        FaceRecognitionConstants.mediapipeWasmPath.toJS,
      ).toDart;

      // Create face landmarker with options using dynamic objects
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

      _faceLandmarker = await _createFaceLandmarkerFromOptions(
        filesetResolver as JSObject,
        options,
      ).toDart as JSFaceLandmarker;

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize MediaPipe: $e');
    }
  }

  /// Detect face landmarks from video element
  List<FaceLandmark>? detectFace(web.HTMLVideoElement video) {
    if (!_isInitialized || _faceLandmarker == null) {
      return null;
    }

    try {
      final result = _faceLandmarker!.detect(video);

      // Access faceLandmarks property
      final faceLandmarksArray = result.getProperty('faceLandmarks'.toJS);
      if (faceLandmarksArray.isUndefinedOrNull) {
        return null;
      }

      // Get length of array
      final length = (faceLandmarksArray as JSObject).getProperty('length'.toJS) as JSNumber;
      if (length.toDartInt == 0) {
        return null;
      }

      // Get first face landmarks
      final firstFace = (faceLandmarksArray as JSObject).getProperty(0.toJS) as JSObject;
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
      _faceLandmarker!.close();
      _faceLandmarker = null;
    }
    _isInitialized = false;
  }
}
