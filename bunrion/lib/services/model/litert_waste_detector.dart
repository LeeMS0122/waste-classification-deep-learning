import 'package:bunrion/core/constants/waste_classes.dart';
import 'package:bunrion/services/model/detection_result.dart';
import 'package:bunrion/services/model/waste_detector.dart';
import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class LiteRtWasteDetector implements WasteDetector {
  LiteRtWasteDetector({this.modelPath = 'assets/models/waste_yolo11s.tflite'});

  final String modelPath;
  YOLO? _model;

  @override
  Future<bool> isModelAvailable() async {
    try {
      await rootBundle.load(modelPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> load() async {
    _model ??= YOLO(modelPath: modelPath, task: YOLOTask.detect, useGpu: true);
    final ok = await _model!.loadModel();
    if (!ok) throw StateError('모델 로딩에 실패했습니다.');
  }

  @override
  Future<List<DetectionResult>> detect(
    Uint8List imageBytes, {
    required double confidenceThreshold,
    required double iouThreshold,
  }) async {
    await load();
    final raw = await _model!.predict(
      imageBytes,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
    );
    final detections = (raw['detections'] as List? ?? const [])
        .whereType<Map>()
        .map(YOLOResult.fromMap)
        .map(
          (item) => DetectionResult(
            classId: WasteClasses.idOf(item.className) ?? item.classIndex,
            confidence: item.confidence,
            boundingBox: item.boundingBox,
            normalizedBox: item.normalizedBox,
          ),
        )
        .where((item) => item.confidence >= 0.25)
        .take(50)
        .toList();
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detections;
  }
}
