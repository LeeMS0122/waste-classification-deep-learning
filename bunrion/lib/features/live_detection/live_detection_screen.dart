import 'dart:async';

import 'package:bunrion/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class LiveDetectionScreen extends ConsumerStatefulWidget {
  const LiveDetectionScreen({super.key});

  @override
  ConsumerState<LiveDetectionScreen> createState() =>
      _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends ConsumerState<LiveDetectionScreen> {
  static const _modelPath = 'assets/models/waste_yolo11s.tflite';

  final _controller = YOLOViewController();
  List<YOLOResult> _detections = const [];
  double? _fps;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threshold = ref.watch(confidenceThresholdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('실시간 탐지')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          YOLOView(
            modelPath: _modelPath,
            task: YOLOTask.detect,
            controller: _controller,
            confidenceThreshold: threshold,
            iouThreshold: 0.45,
            useGpu: true,
            lensFacing: LensFacing.back,
            streamingConfig: const YOLOStreamingConfig(
              includeDetections: true,
              includeClassifications: false,
              includeProcessingTimeMs: false,
              includeFps: true,
              maxFPS: 12,
              inferenceFrequency: 12,
            ),
            onResult: (results) {
              if (!mounted) return;
              setState(() => _detections = results.take(12).toList());
            },
            onPerformanceMetrics: (metrics) {
              if (!mounted) return;
              setState(() => _fps = metrics.fps);
            },
            onModelLoad: (_, _) {
              if (!mounted) return;
              setState(() {
                _loaded = true;
                _error = null;
              });
              unawaited(_controller.setNumItemsThreshold(12));
            },
            onModelError: (error, _, _) {
              if (!mounted) return;
              setState(() => _error = '실시간 탐지를 시작하지 못했습니다.');
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _LiveStatusPanel(
              detections: _detections,
              fps: _fps,
              error: _error,
              loaded: _loaded,
              onSwitchCamera: _switchCamera,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchCamera() async {
    _controller.resetTorchState();
    await _controller.switchCamera();
  }
}

class _LiveStatusPanel extends StatelessWidget {
  const _LiveStatusPanel({
    required this.detections,
    required this.fps,
    required this.error,
    required this.loaded,
    required this.onSwitchCamera,
  });

  final List<YOLOResult> detections;
  final double? fps;
  final String? error;
  final bool loaded;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    final top = detections.isEmpty ? null : detections.first;
    final fpsLabel = fps == null ? null : '${fps!.toStringAsFixed(1)} FPS';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              error != null
                  ? Icons.error_outline
                  : top == null
                  ? Icons.center_focus_strong
                  : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error ??
                    (top == null
                        ? loaded
                              ? '물체를 화면 중앙에 비춰 주세요'
                              : '모델 준비 중'
                        : '${top.className} ${(top.confidence * 100).toStringAsFixed(1)}%${fpsLabel == null ? '' : ' · $fpsLabel'}'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: onSwitchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
