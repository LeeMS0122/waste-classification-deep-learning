import 'package:bunrion/app/providers.dart';
import 'package:bunrion/core/constants/waste_classes.dart';
import 'package:bunrion/features/detection/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;
    context.push('/analysis', extra: image.path);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('분리ON'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '이 쓰레기, 어디에 버려야 할까요?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/camera'),
            icon: const Icon(Icons.photo_camera),
            label: const Text('카메라로 촬영하기'),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/live-detection'),
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('실시간 탐지하기'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('갤러리에서 불러오기'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: '폐기물 이름 검색',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => context.go('/dictionary'),
          ),
          const SizedBox(height: 22),
          _SectionTitle('7개 품목 바로가기'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WasteClasses.names.entries
                .map(
                  (entry) => ActionChip(
                    avatar: const Icon(Icons.recycling, size: 18),
                    label: Text(entry.value),
                    onPressed: () => context.push(
                      '/result',
                      extra: ResultScreenData.manual(entry.key, ''),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          _PrinciplesCard(),
          const SizedBox(height: 22),
          _SectionTitle('최근 인식 기록'),
          history.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => const Text('기록을 불러오지 못했습니다.'),
            data: (items) => items.isEmpty
                ? const Text('아직 저장된 기록이 없습니다.')
                : Column(
                    children: items
                        .take(3)
                        .map(
                          (item) => ListTile(
                            leading: const Icon(Icons.image_outlined),
                            title: Text(item.classNames.join(', ')),
                            subtitle: Text(
                              '${item.createdAt.year}.${item.createdAt.month}.${item.createdAt.day} · 모델 신뢰도 ${(item.topConfidence * 100).toStringAsFixed(1)}%',
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _PrinciplesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = ['내용물을 비운다', '이물질을 제거한다', '다른 재질을 분리한다', '지역별 배출방법을 확인한다'];
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '분리배출 기본 원칙',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...items.indexed.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(radius: 13, child: Text('${item.$1 + 1}')),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.$2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
