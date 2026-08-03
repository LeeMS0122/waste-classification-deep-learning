import 'dart:math';
import 'dart:ui';

import 'package:bunrion/services/model/detection_result.dart';

double intersectionOverUnion(Rect a, Rect b) {
  final left = max(a.left, b.left);
  final top = max(a.top, b.top);
  final right = min(a.right, b.right);
  final bottom = min(a.bottom, b.bottom);
  final intersection = max(0, right - left) * max(0, bottom - top);
  final union = a.width * a.height + b.width * b.height - intersection;
  return union <= 0 ? 0 : intersection / union;
}

List<DetectionResult> nonMaxSuppression(
  List<DetectionResult> input, {
  required double iouThreshold,
  int maxDetections = 50,
}) {
  final sorted = [...input]
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
  final kept = <DetectionResult>[];
  for (final candidate in sorted) {
    final overlapsSameClass = kept.any(
      (item) =>
          item.classId == candidate.classId &&
          intersectionOverUnion(item.boundingBox, candidate.boundingBox) >
              iouThreshold,
    );
    if (!overlapsSameClass) kept.add(candidate);
    if (kept.length >= maxDetections) break;
  }
  return kept;
}
