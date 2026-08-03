import 'dart:io';
import 'dart:ui' as ui;

import 'package:bunrion/app/providers.dart';
import 'package:bunrion/core/constants/waste_classes.dart';
import 'package:bunrion/data/disposal_guide_repository.dart';
import 'package:bunrion/services/model/detection_result.dart';
import 'package:bunrion/services/storage/history_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreenData {
  const ResultScreenData({
    required this.imagePath,
    required this.detections,
    this.edited = false,
  });

  final String imagePath;
  final List<DetectionResult> detections;
  final bool edited;

  factory ResultScreenData.manual(int classId, String imagePath) =>
      ResultScreenData(
        imagePath: imagePath,
        edited: true,
        detections: [
          DetectionResult(
            classId: classId,
            confidence: 1,
            boundingBox: ui.Rect.zero,
          ),
        ],
      );
}

class ResultScreen extends ConsumerWidget {
  const ResultScreen({required this.data, super.key});

  final ResultScreenData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = ref.watch(confidenceThresholdProvider);
    final confident = data.detections
        .where(
          (item) => item.band(threshold) == DetectionConfidenceBand.confident,
        )
        .toList();
    final low = data.detections
        .where((item) => item.band(threshold) == DetectionConfidenceBand.low)
        .toList();
    final display = confident.isNotEmpty ? confident : low;
    final classIds = display.map((item) => item.classId).toSet().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('인식 결과')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (data.imagePath.isNotEmpty)
            _ResultImage(
              imagePath: data.imagePath,
              detections: data.detections,
            ),
          const SizedBox(height: 16),
          if (display.isEmpty)
            _UnsupportedCard(imagePath: data.imagePath)
          else if (low.isNotEmpty && confident.isEmpty)
            _LowConfidenceCard(detection: low.first),
          ...classIds.map(
            (id) => _GuideResultCard(
              classId: id,
              detections: display.where((item) => item.classId == id).toList(),
              allDetections: display,
              imagePath: data.imagePath,
              edited: data.edited,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.imagePath, required this.detections});

  final String imagePath;
  final List<DetectionResult> detections;

  Future<ui.Image> _decode() async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _decode(),
      builder: (context, snapshot) => AspectRatio(
        aspectRatio: snapshot.hasData
            ? snapshot.data!.width / snapshot.data!.height
            : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(imagePath), fit: BoxFit.contain),
              if (snapshot.hasData)
                CustomPaint(
                  painter: _BoxPainter(
                    detections,
                    Size(
                      snapshot.data!.width.toDouble(),
                      snapshot.data!.height.toDouble(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.detections, this.imageSize);

  final List<DetectionResult> detections;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(BoxFit.contain, imageSize, size);
    final renderSize = fitted.destination;
    final dx = (size.width - renderSize.width) / 2;
    final dy = (size.height - renderSize.height) / 2;
    final paint = Paint()
      ..color = const Color(0xff1f8f55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final item in detections) {
      if (item.boundingBox == Rect.zero) continue;
      final rect = _displayRect(item, renderSize).shift(Offset(dx, dy));
      canvas.drawRect(rect, paint);
      textPainter.text = TextSpan(
        text: '${item.className} ${item.confidenceLabel}',
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Color(0xff1f8f55),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout(maxWidth: size.width);
      final labelX = rect.left.clamp(
        0,
        (size.width - textPainter.width).clamp(0, size.width),
      );
      textPainter.paint(
        canvas,
        Offset(labelX.toDouble(), (rect.top - 20).clamp(0, size.height)),
      );
    }
  }

  Rect _displayRect(DetectionResult item, Size renderSize) {
    final normalized = item.normalizedBox;
    final hasNormalized =
        normalized.width > 0 &&
        normalized.height > 0 &&
        normalized.left >= 0 &&
        normalized.top >= 0 &&
        normalized.right <= 1.05 &&
        normalized.bottom <= 1.05;
    if (hasNormalized) {
      return Rect.fromLTRB(
        normalized.left.clamp(0, 1) * renderSize.width,
        normalized.top.clamp(0, 1) * renderSize.height,
        normalized.right.clamp(0, 1) * renderSize.width,
        normalized.bottom.clamp(0, 1) * renderSize.height,
      );
    }

    final sx = renderSize.width / imageSize.width;
    final sy = renderSize.height / imageSize.height;
    return Rect.fromLTRB(
      item.boundingBox.left * sx,
      item.boundingBox.top * sy,
      item.boundingBox.right * sx,
      item.boundingBox.bottom * sy,
    );
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) =>
      oldDelegate.detections != detections;
}

class _LowConfidenceCard extends StatelessWidget {
  const _LowConfidenceCard({required this.detection});

  final DetectionResult detection;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('정확한 인식이 어려워요.'),
        subtitle: Text(
          '물체가 화면 중앙에 오도록 밝은 곳에서 다시 촬영해 주세요.\n예상 결과: ${detection.className} · 모델 신뢰도 ${detection.confidenceLabel}',
        ),
      ),
    );
  }
}

class _UnsupportedCard extends StatelessWidget {
  const _UnsupportedCard({required this.imagePath});
  final String imagePath;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.info_outline, size: 42),
            const SizedBox(height: 8),
            const Text(
              '현재 모델이 지원하지 않는 품목일 수 있습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '음식물쓰레기, 폐건전지, 전자제품, 의류, 폐의약품, 도자기 등은 7개 재활용 품목으로 단정하지 않습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => context.go('/camera'),
              child: const Text('다시 촬영'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/dictionary'),
              child: const Text('7개 품목 중 직접 선택'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideResultCard extends ConsumerWidget {
  const _GuideResultCard({
    required this.classId,
    required this.detections,
    required this.allDetections,
    required this.imagePath,
    required this.edited,
  });

  final int classId;
  final List<DetectionResult> detections;
  final List<DetectionResult> allDetections;
  final String imagePath;
  final bool edited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref
        .watch(guidesProvider)
        .maybeWhen(data: _findGuide, orElse: () => null);
    final confidence = detections
        .map((item) => item.confidence)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              WasteClasses.nameOf(classId),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              confidence >= 1
                  ? '사용자가 직접 선택한 결과'
                  : '모델 신뢰도 ${(confidence * 100).toStringAsFixed(1)}%',
            ),
            const Divider(height: 24),
            if (guide == null)
              const Text('안내 데이터를 불러오는 중입니다.')
            else
              _GuideBody(guide: guide),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/dictionary'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('직접 수정'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/camera'),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('다시 촬영'),
                ),
                FilledButton.icon(
                  onPressed: guide == null
                      ? null
                      : () => launchUrl(
                          Uri.parse(guide.officialSourceUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('공식 안내 확인'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final storage = await ref.read(
                      historyStorageProvider.future,
                    );
                    await storage.save(
                      HistoryItem(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        imagePath: imagePath,
                        createdAt: DateTime.now(),
                        classNames: allDetections
                            .map((item) => item.className)
                            .toSet()
                            .toList(),
                        topConfidence: allDetections
                            .map((item) => item.confidence)
                            .fold<double>(0, (a, b) => a > b ? a : b),
                        edited: edited,
                        detections: allDetections,
                      ),
                    );
                    ref.invalidate(historyProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('결과를 기기에 저장했습니다.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('결과 저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DisposalGuide? _findGuide(List<DisposalGuide> guides) {
    for (final guide in guides) {
      if (guide.classId == classId) return guide;
    }
    return null;
  }
}

class _GuideBody extends StatelessWidget {
  const _GuideBody({required this.guide});
  final DisposalGuide guide;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          guide.shortDescription,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text('분리배출 순서', style: TextStyle(fontWeight: FontWeight.w800)),
        ...guide.steps.indexed.map(
          (step) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 13, child: Text('${step.$1 + 1}')),
            title: Text(step.$2),
          ),
        ),
        const SizedBox(height: 8),
        const Text('주의사항', style: TextStyle(fontWeight: FontWeight.w800)),
        ...guide.cautions.map(
          (text) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.warning_amber_outlined),
            title: Text(text),
          ),
        ),
        const SizedBox(height: 8),
        Text(guide.regionalNotice),
      ],
    );
  }
}
