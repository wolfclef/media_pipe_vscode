import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

class CameraPreviewWidget extends StatefulWidget {
  final web.HTMLVideoElement videoElement;
  final String? viewId;

  const CameraPreviewWidget({
    super.key,
    required this.videoElement,
    this.viewId,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  late final String _uniqueViewId;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    // Generate unique view ID using timestamp to avoid conflicts
    _uniqueViewId = '${widget.viewId ?? 'video-element'}-${DateTime.now().microsecondsSinceEpoch}';
    _registerViewFactory();
  }

  void _registerViewFactory() {
    if (_isRegistered) return;

    try {
      // Register the video element as a platform view with unique ID
      ui_web.platformViewRegistry.registerViewFactory(
        _uniqueViewId,
        (int viewId) => widget.videoElement,
      );
      _isRegistered = true;
    } catch (e) {
      // Ignore if already registered
      debugPrint('View factory already registered: $_uniqueViewId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateY(3.14159), // 좌우 반전 (거울 모드) - 180도 Y축 회전
        child: HtmlElementView(
          viewType: _uniqueViewId,
        ),
      ),
    );
  }
}
