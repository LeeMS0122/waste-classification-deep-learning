import 'dart:ui';

import 'package:bunrion/core/constants/waste_classes.dart';

enum DetectionConfidenceBand { confident, low, unsupported }

class DetectionResult {
  const DetectionResult({
    required this.classId,
    required this.confidence,
    required this.boundingBox,
    this.normalizedBox = Rect.zero,
  });

  final int classId;
  final double confidence;
  final Rect boundingBox;
  final Rect normalizedBox;

  String get className => WasteClasses.nameOf(classId);
  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(1)}%';

  DetectionConfidenceBand band(double threshold) {
    if (!WasteClasses.isSupported(classId) || confidence < 0.25) {
      return DetectionConfidenceBand.unsupported;
    }
    if (confidence < threshold) return DetectionConfidenceBand.low;
    return DetectionConfidenceBand.confident;
  }

  Map<String, dynamic> toJson() => {
    'classId': classId,
    'confidence': confidence,
    'box': {
      'left': boundingBox.left,
      'top': boundingBox.top,
      'right': boundingBox.right,
      'bottom': boundingBox.bottom,
    },
    'normalizedBox': {
      'left': normalizedBox.left,
      'top': normalizedBox.top,
      'right': normalizedBox.right,
      'bottom': normalizedBox.bottom,
    },
  };

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final box = json['box'] as Map<String, dynamic>;
    final normalizedBox = json['normalizedBox'] as Map<String, dynamic>?;
    return DetectionResult(
      classId: json['classId'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: Rect.fromLTRB(
        (box['left'] as num).toDouble(),
        (box['top'] as num).toDouble(),
        (box['right'] as num).toDouble(),
        (box['bottom'] as num).toDouble(),
      ),
      normalizedBox: normalizedBox == null
          ? Rect.zero
          : Rect.fromLTRB(
              (normalizedBox['left'] as num).toDouble(),
              (normalizedBox['top'] as num).toDouble(),
              (normalizedBox['right'] as num).toDouble(),
              (normalizedBox['bottom'] as num).toDouble(),
            ),
    );
  }
}
