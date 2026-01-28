import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../utils/constants.dart';

class CameraService {
  web.HTMLVideoElement? _videoElement;
  web.MediaStream? _stream;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  web.HTMLVideoElement? get videoElement => _videoElement;

  /// Start the camera and create video element
  Future<void> startCamera() async {
    try {
      // Create video element
      _videoElement = web.document.createElement('video') as web.HTMLVideoElement;
      _videoElement!.width = FaceRecognitionConstants.cameraWidth;
      _videoElement!.height = FaceRecognitionConstants.cameraHeight;
      _videoElement!.autoplay = true;

      // Request camera permission and get stream
      final mediaDevices = web.window.navigator.mediaDevices;

      // Create constraints as a JS object
      final constraints = <String, dynamic>{
        'video': {
          'width': FaceRecognitionConstants.cameraWidth,
          'height': FaceRecognitionConstants.cameraHeight,
          'facingMode': 'user',
        },
        'audio': false,
      }.jsify() as web.MediaStreamConstraints;

      // Get user media
      _stream = await mediaDevices.getUserMedia(constraints).toDart as web.MediaStream;

      // Set video source
      _videoElement!.srcObject = _stream;

      // Wait for video to be ready
      final completer = Completer<void>();
      _videoElement!.onLoadedMetadata.listen((_) {
        _videoElement!.play();
        completer.complete();
      });

      await completer.future;
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to start camera: $e');
    }
  }

  /// Stop the camera and release resources
  void stopCamera() {
    if (_stream != null) {
      final tracks = _stream!.getTracks();
      final trackLength = tracks.length;
      for (int i = 0; i < trackLength; i++) {
        (tracks[i] as web.MediaStreamTrack).stop();
      }
      _stream = null;
    }

    if (_videoElement != null) {
      _videoElement!.srcObject = null;
      _videoElement = null;
    }

    _isInitialized = false;
  }

  /// Dispose of all resources
  void dispose() {
    stopCamera();
  }
}
