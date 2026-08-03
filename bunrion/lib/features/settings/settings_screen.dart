import 'package:bunrion/app/providers.dart';
import 'package:bunrion/core/constants/waste_classes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = ref.watch(confidenceThresholdProvider);
    final modelAvailable = ref.watch(modelAvailableProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('설정 및 정보')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Confidence threshold',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: threshold,
            min: 0.25,
            max: 0.80,
            divisions: 55,
            label: threshold.toStringAsFixed(2),
            onChanged: (value) =>
                ref.read(confidenceThresholdProvider.notifier).set(value),
          ),
          Text(
            '현재 기준: ${(threshold * 100).toStringAsFixed(0)}% 이상을 정상 인식 결과로 표시합니다.',
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.memory_outlined),
            title: const Text('모델 정보'),
            subtitle: Text(
              'YOLO11s LiteRT · 입력 640x640 · ${modelAvailable.maybeWhen(data: (ok) => ok ? '모델 파일 확인됨' : '모델 파일 없음', orElse: () => '확인 중')}',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('개인정보 안내'),
            subtitle: Text('사진은 외부 서버로 전송하지 않고 기기 내부에서 처리합니다. 기록도 기기에만 저장됩니다.'),
          ),
          const ListTile(
            leading: Icon(Icons.location_city_outlined),
            title: Text('지역별 기준 우선'),
            subtitle: Text(
              '배출방법은 지역별로 다를 수 있으므로 관할 지방자치단체의 배출 기준을 우선 확인해 주세요.',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '지원 클래스',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WasteClasses.names.values
                .map((name) => Chip(label: Text(name)))
                .toList(),
          ),
          const SizedBox(height: 22),
          const Text('앱 버전 1.0.0 · 공식 분리배출 안내 출처: 생활폐기물 분리배출 누리집'),
        ],
      ),
    );
  }
}
