import 'package:flutter/material.dart';
import '../models/face_data.dart';
import '../utils/constants.dart';

class ResultDisplayWidget extends StatelessWidget {
  final MatchResult? matchResult;

  const ResultDisplayWidget({
    super.key,
    this.matchResult,
  });

  @override
  Widget build(BuildContext context) {
    if (matchResult == null) {
      return _buildNoMatch();
    }

    final confidence = matchResult!.confidencePercentage;
    final isHighConfidence =
        matchResult!.confidence >= FaceRecognitionConstants.highConfidence;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighConfidence
            ? Colors.green.withOpacity(0.9)
            : Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHighConfidence ? Icons.check_circle : Icons.face,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            matchResult!.user.userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${confidence.toStringAsFixed(1)}% 일치',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildConfidenceBar(confidence),
        ],
      ),
    );
  }

  Widget _buildNoMatch() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cancel,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 12),
          Text(
            '알 수 없는 사람',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '등록되지 않은 얼굴입니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    return Container(
      width: 200,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: confidence / 100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
