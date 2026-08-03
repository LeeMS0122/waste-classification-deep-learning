import 'dart:ui';

import 'package:bunrion/core/constants/waste_classes.dart';
import 'package:bunrion/services/model/detection_result.dart';
import 'package:bunrion/services/model/image_preprocessor.dart';
import 'package:bunrion/services/model/nms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('class id maps to Korean class name', () {
    expect(WasteClasses.nameOf(0), '플라스틱류');
    expect(WasteClasses.nameOf(6), '스티로폼류');
    expect(WasteClasses.idOf('캔류'), 4);
    expect(WasteClasses.idOf(' 비닐류 '), 5);
    expect(WasteClasses.isSupported(7), isFalse);
  });

  test('confidence threshold bands are classified', () {
    final high = DetectionResult(
      classId: 0,
      confidence: 0.45,
      boundingBox: Rect.zero,
    );
    final low = DetectionResult(
      classId: 0,
      confidence: 0.30,
      boundingBox: Rect.zero,
    );
    final unsupported = DetectionResult(
      classId: 0,
      confidence: 0.24,
      boundingBox: Rect.zero,
    );
    expect(high.band(0.45), DetectionConfidenceBand.confident);
    expect(low.band(0.45), DetectionConfidenceBand.low);
    expect(unsupported.band(0.45), DetectionConfidenceBand.unsupported);
  });

  test('nms keeps highest confidence overlapping box per class', () {
    final input = [
      DetectionResult(
        classId: 0,
        confidence: 0.9,
        boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
      ),
      DetectionResult(
        classId: 0,
        confidence: 0.8,
        boundingBox: const Rect.fromLTWH(10, 10, 100, 100),
      ),
      DetectionResult(
        classId: 1,
        confidence: 0.7,
        boundingBox: const Rect.fromLTWH(10, 10, 100, 100),
      ),
    ];
    final kept = nonMaxSuppression(input, iouThreshold: 0.5);
    expect(kept.length, 2);
    expect(kept.first.confidence, 0.9);
    expect(kept.map((item) => item.classId), containsAll([0, 1]));
  });

  test(
    'letterbox restores model coordinates to original image coordinates',
    () {
      final transform = letterboxFor(imageWidth: 1280, imageHeight: 720);
      final restored = transform.restore(
        const Rect.fromLTRB(320, 140, 640, 500),
      );
      expect(restored.left, closeTo(640, 0.01));
      expect(restored.top, closeTo(0, 0.01));
      expect(restored.right, closeTo(1280, 0.01));
    },
  );
}
