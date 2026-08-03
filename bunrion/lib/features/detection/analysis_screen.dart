import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bunrion/app/providers.dart';
import 'package:bunrion/core/utils/image_file_preparer.dart';
import 'package:bunrion/features/detection/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  String? _error;
  String? _previewPath;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    setState(() => _error = null);
    try {
      final prepared = await prepareImageForInference(widget.imagePath);
      if (!mounted) return;
      setState(() => _previewPath = prepared.path);
      final detector = ref.read(detectorProvider);
      final threshold = ref.read(confidenceThresholdProvider);
      final results = await detector
          .detect(
            Uint8List.fromList(prepared.bytes),
            confidenceThreshold: threshold,
            iouThreshold: 0.50,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      context.go(
        '/result',
        extra: ResultScreenData(imagePath: prepared.path, detections: results),
      );
    } on TimeoutException {
      if (mounted) setState(() => _error = '분석이 20초 이상 걸렸습니다. 다시 시도해 주세요.');
    } catch (_) {
      if (mounted) {
        setState(() => _error = '추론에 실패했습니다. 모델 파일과 이미지 형식을 확인해 주세요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('분석 중')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(_previewPath ?? widget.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_error == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              const Text('폐기물 종류를 확인하고 있어요'),
            ] else ...[
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _run,
                icon: const Icon(Icons.refresh),
                label: const Text('재시도'),
              ),
              TextButton(
                onPressed: () => context.go('/dictionary'),
                child: const Text('7개 품목 중 직접 선택'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
