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
      // Clean up any existing resources first
      stopCamera();

      // Create video element with all necessary attributes
      _videoElement = web.document.createElement('video') as web.HTMLVideoElement;
      _videoElement!.width = FaceRecognitionConstants.cameraWidth;
      _videoElement!.height = FaceRecognitionConstants.cameraHeight;
      _videoElement!.autoplay = true;
      _videoElement!.playsInline = true; // Important for mobile
      _videoElement!.muted = true; // Required for autoplay in some browsers

      // Request camera permission and get stream
      final mediaDevices = web.window.navigator.mediaDevices;

      // Create constraints with ideal settings
      final constraints = <String, dynamic>{
        'video': {
          'width': {'ideal': FaceRecognitionConstants.cameraWidth},
          'height': {'ideal': FaceRecognitionConstants.cameraHeight},
          'facingMode': 'user',
        },
        'audio': false,
      }.jsify() as web.MediaStreamConstraints;

      // Get user media with timeout
      final streamFuture = mediaDevices.getUserMedia(constraints).toDart;
      _stream = await streamFuture.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Camera initialization timeout');
        },
      ) as web.MediaStream;

      // Set video source
      _videoElement!.srcObject = _stream;

      // Wait for video to be ready with timeout
      final completer = Completer<void>();
      Timer? timeoutTimer;

      final subscription = _videoElement!.onLoadedMetadata.listen((_) async {
        timeoutTimer?.cancel();
        try {
          await _videoElement!.play().toDart;
          completer.complete();
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      });

      // Set timeout
      timeoutTimer = Timer(const Duration(seconds: 10), () {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Video ready timeout'));
        }
      });

      await completer.future;
      _isInitialized = true;
    } catch (e) {
      // Clean up on error
      stopCamera();
      throw Exception('Failed to start camera: $e');
    }
  }

  /// Stop the camera and release resources
  void stopCamera() {
    if (_stream != null) {
      try {
        final tracks = _stream!.getTracks();
        final trackLength = tracks.length;
        for (int i = 0; i < trackLength; i++) {
          final track = tracks[i];
          if (track != null) {
            track.stop();
          }
        }
      } catch (e) {
        // Ignore errors during cleanup
      }
      _stream = null;
    }

    if (_videoElement != null) {
      try {
        _videoElement!.srcObject = null;
        _videoElement!.pause();
      } catch (e) {
        // Ignore errors during cleanup
      }
      _videoElement = null;
    }

    _isInitialized = false;
  }

  /// Dispose of all resources
  void dispose() {
    stopCamera();
  }
}
