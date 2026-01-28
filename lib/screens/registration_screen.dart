import 'dart:async';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/mediapipe_service.dart';
import '../services/face_recognition_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/face_overlay_widget.dart';
import '../utils/constants.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final CameraService _cameraService = CameraService();
  final MediaPipeService _mediaPipeService = MediaPipeService();
  final FaceRecognitionService _recognitionService = FaceRecognitionService();
  final TextEditingController _nameController = TextEditingController();

  List<FaceLandmark>? _currentLandmarks;
  bool _isInitializing = true;
  bool _isFaceDetected = false;
  String _statusMessage = '초기화 중...';
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _statusMessage = '카메라 시작 중...';
      });

      await _cameraService.startCamera();

      setState(() {
        _statusMessage = 'MediaPipe 로딩 중...';
      });

      await _mediaPipeService.initialize();

      setState(() {
        _isInitializing = false;
        _statusMessage = '얼굴을 프레임에 맞춰주세요';
      });

      // Start face detection
      _startDetection();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusMessage = '초기화 실패: $e';
      });
    }
  }

  void _startDetection() {
    _detectionTimer = Timer.periodic(
      Duration(milliseconds: FaceRecognitionConstants.detectionIntervalMs),
      (_) => _detectFace(),
    );
  }

  void _detectFace() {
    if (_cameraService.videoElement == null) return;

    final landmarks = _mediaPipeService.detectFace(_cameraService.videoElement!);

    setState(() {
      _currentLandmarks = landmarks;
      _isFaceDetected = landmarks != null;

      if (_isFaceDetected) {
        _statusMessage = '얼굴이 감지되었습니다';
      } else {
        _statusMessage = '얼굴을 프레임에 맞춰주세요';
      }
    });
  }

  Future<void> _captureFace() async {
    if (!_isFaceDetected || _currentLandmarks == null) {
      _showSnackBar('얼굴이 감지되지 않았습니다', isError: true);
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('이름을 입력해주세요', isError: true);
      return;
    }

    try {
      // Generate unique user ID
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      // Register face
      await _recognitionService.registerFace(
        userId: userId,
        userName: name,
        landmarks: _currentLandmarks!,
      );

      if (!mounted) return;

      _showSnackBar('$name님의 얼굴이 등록되었습니다', isError: false);

      // Wait a bit and go back
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('등록 실패: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraService.dispose();
    _mediaPipeService.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('얼굴 등록'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isInitializing
          ? _buildLoadingView()
          : _buildCameraView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            _statusMessage,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        // Camera preview with overlay
        Expanded(
          child: Stack(
            children: [
              // Camera preview
              if (_cameraService.videoElement != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: FaceRecognitionConstants.cameraWidth /
                        FaceRecognitionConstants.cameraHeight,
                    child: CameraPreviewWidget(
                      videoElement: _cameraService.videoElement!,
                      viewId: 'camera-registration',
                    ),
                  ),
                ),

              // Face overlay
              if (_cameraService.videoElement != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: FaceRecognitionConstants.cameraWidth /
                        FaceRecognitionConstants.cameraHeight,
                    child: FaceOverlayWidget(
                      landmarks: _currentLandmarks,
                      videoSize: Size(
                        FaceRecognitionConstants.cameraWidth.toDouble(),
                        FaceRecognitionConstants.cameraHeight.toDouble(),
                      ),
                    ),
                  ),
                ),

              // Status indicator
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _isFaceDetected
                          ? Colors.green.withOpacity(0.9)
                          : Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFaceDetected ? Icons.check_circle : Icons.info,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Input section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  hintText: '등록할 사람의 이름을 입력하세요',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isFaceDetected ? _captureFace : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt),
                      SizedBox(width: 8),
                      Text(
                        '촬영하고 등록',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
