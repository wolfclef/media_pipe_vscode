import 'package:flutter/material.dart';
import '../services/mediapipe_service.dart';

class FaceOverlayWidget extends StatelessWidget {
  final List<FaceLandmark>? landmarks;
  final Size videoSize;
  final bool showLandmarks;

  const FaceOverlayWidget({
    super.key,
    this.landmarks,
    required this.videoSize,
    this.showLandmarks = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: videoSize,
      painter: _FaceOverlayPainter(
        landmarks: landmarks,
        showLandmarks: showLandmarks,
      ),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  final List<FaceLandmark>? landmarks;
  final bool showLandmarks;

  _FaceOverlayPainter({
    this.landmarks,
    this.showLandmarks = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null || landmarks!.isEmpty) {
      return;
    }

    // Calculate bounding box
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final landmark in landmarks!) {
      final x = landmark.x * size.width;
      final y = landmark.y * size.height;

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // Add some padding to the bounding box
    final padding = 20.0;
    minX = (minX - padding).clamp(0, size.width);
    maxX = (maxX + padding).clamp(0, size.width);
    minY = (minY - padding).clamp(0, size.height);
    maxY = (maxY + padding).clamp(0, size.height);

    // Draw bounding box
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );

    // Optionally draw landmark points
    if (showLandmarks) {
      final pointPaint = Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      for (final landmark in landmarks!) {
        final x = landmark.x * size.width;
        final y = landmark.y * size.height;
        canvas.drawCircle(Offset(x, y), 1.5, pointPaint);
      }
    }

    // Draw corner indicators
    _drawCornerIndicators(canvas, rect, paint);
  }

  void _drawCornerIndicators(Canvas canvas, Rect rect, Paint paint) {
    final cornerLength = 20.0;
    final path = Path();

    // Top-left corner
    path.moveTo(rect.left, rect.top + cornerLength);
    path.lineTo(rect.left, rect.top);
    path.lineTo(rect.left + cornerLength, rect.top);

    // Top-right corner
    path.moveTo(rect.right - cornerLength, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.top + cornerLength);

    // Bottom-right corner
    path.moveTo(rect.right, rect.bottom - cornerLength);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right - cornerLength, rect.bottom);

    // Bottom-left corner
    path.moveTo(rect.left + cornerLength, rect.bottom);
    path.lineTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.bottom - cornerLength);

    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawPath(path, cornerPaint);
  }

  @override
  bool shouldRepaint(_FaceOverlayPainter oldDelegate) {
    return landmarks != oldDelegate.landmarks ||
        showLandmarks != oldDelegate.showLandmarks;
  }
}
