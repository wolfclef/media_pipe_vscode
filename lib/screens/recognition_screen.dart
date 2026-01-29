import 'dart:async';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/mediapipe_service.dart';
import '../services/face_recognition_service.dart';
import '../models/face_data.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/face_overlay_widget.dart';
import '../widgets/result_display_widget.dart';
import '../utils/constants.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  final CameraService _cameraService = CameraService();
  final MediaPipeService _mediaPipeService = MediaPipeService();
  final FaceRecognitionService _recognitionService = FaceRecognitionService();

  List<FaceLandmark>? _currentLandmarks;
  MatchResult? _matchResult;
  bool _isInitializing = true;
  bool _isFaceDetected = false;
  String _statusMessage = '초기화 중...';
  Timer? _detectionTimer;
  int _registeredUserCount = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _statusMessage = '등록된 사용자 확인 중...';
      });

      // Check registered users
      _registeredUserCount = await _recognitionService.getRegisteredUserCount();

      if (_registeredUserCount == 0) {
        setState(() {
          _isInitializing = false;
          _statusMessage = '등록된 사용자가 없습니다';
        });
        return;
      }

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

      // Start face detection and recognition
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
      (_) => _detectAndRecognize(),
    );
  }

  Future<void> _detectAndRecognize() async {
    if (_cameraService.videoElement == null) return;

    final landmarks = _mediaPipeService.detectFace(_cameraService.videoElement!);

    if (landmarks == null) {
      setState(() {
        _currentLandmarks = null;
        _matchResult = null;
        _isFaceDetected = false;
        _statusMessage = '얼굴을 프레임에 맞춰주세요';
      });
      return;
    }

    // Recognize face
    final matchResult = await _recognitionService.recognizeFace(landmarks);

    setState(() {
      _currentLandmarks = landmarks;
      _matchResult = matchResult;
      _isFaceDetected = true;

      if (matchResult != null) {
        _statusMessage = '${matchResult.user.userName} 인식됨';
      } else {
        _statusMessage = '알 수 없는 사람';
      }
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraService.dispose();
    _mediaPipeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('얼굴 인식'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: '등록된 사용자',
            onPressed: _showRegisteredUsers,
          ),
        ],
      ),
      body: _isInitializing
          ? _buildLoadingView()
          : _registeredUserCount == 0
              ? _buildNoUsersView()
              : _buildRecognitionView(),
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

  Widget _buildNoUsersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            '등록된 사용자가 없습니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '먼저 얼굴을 등록해주세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecognitionView() {
    return Column(
      children: [
        // Camera preview with overlay
        Expanded(
          child: Stack(
            children: [
              // Camera preview with overlay (mirrored together)
              if (_cameraService.videoElement != null)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159),
                  child: Stack(
                    children: [
                      // Camera preview
                      Center(
                        child: AspectRatio(
                          aspectRatio: FaceRecognitionConstants.cameraWidth /
                              FaceRecognitionConstants.cameraHeight,
                          child: CameraPreviewWidget(
                            videoElement: _cameraService.videoElement!,
                            viewId: 'camera-recognition',
                          ),
                        ),
                      ),

                      // Face overlay
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
                            showLandmarks: true, // 랜드마크 표시
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Result display
              if (_isFaceDetected)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ResultDisplayWidget(
                    matchResult: _matchResult,
                  ),
                ),

              // Status indicator (when no face detected)
              if (!_isFaceDetected)
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
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info,
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

        // Info bar
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '등록된 사용자: $_registeredUserCount명',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showRegisteredUsers() async {
    final users = await _recognitionService.getAllRegisteredUsers();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('등록된 사용자'),
        content: users.isEmpty
            ? const Text('등록된 사용자가 없습니다')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(user.userName),
                      subtitle: Text(
                        '등록일: ${_formatDate(user.registeredAt)}',
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
