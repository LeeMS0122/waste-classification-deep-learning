import 'dart:typed_data';

import 'package:bunrion/services/model/detection_result.dart';

abstract class WasteDetector {
  Future<void> load();
  Future<bool> isModelAvailable();
  Future<List<DetectionResult>> detect(
    Uint8List imageBytes, {
    required double confidenceThreshold,
    required double iouThreshold,
  });
}
