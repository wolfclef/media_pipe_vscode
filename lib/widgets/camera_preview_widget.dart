import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

class CameraPreviewWidget extends StatefulWidget {
  final web.HTMLVideoElement videoElement;
  final String viewId;

  const CameraPreviewWidget({
    super.key,
    required this.videoElement,
    required this.viewId,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  @override
  void initState() {
    super.initState();
    _registerViewFactory();
  }

  void _registerViewFactory() {
    // Register the video element as a platform view
    ui_web.platformViewRegistry.registerViewFactory(
      widget.viewId,
      (int viewId) => widget.videoElement,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: HtmlElementView(
        viewType: widget.viewId,
      ),
    );
  }
}
