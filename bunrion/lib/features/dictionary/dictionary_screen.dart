import 'package:bunrion/app/providers.dart';
import 'package:bunrion/data/disposal_guide_repository.dart';
import 'package:bunrion/features/detection/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final guides = ref.watch(guidesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('품목사전')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: '예: 페트병, 택배상자, 과자봉지',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          const Text(
            '검색 결과는 모델의 7개 분류와 연결된 안내이며, 실제 재활용 가능 여부는 오염도와 지역 기준에 따라 달라질 수 있습니다.',
          ),
          const SizedBox(height: 16),
          guides.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const Text('품목 안내 데이터를 불러오지 못했습니다.'),
            data: (items) {
              final filtered = _filter(items);
              return Column(
                children: filtered
                    .map((guide) => _GuideTile(guide: guide))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<DisposalGuide> _filter(List<DisposalGuide> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (guide) =>
              guide.className.toLowerCase().contains(q) ||
              guide.keywords.any(
                (keyword) => keyword.toLowerCase().contains(q),
              ),
        )
        .toList();
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.guide});

  final DisposalGuide guide;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.recycling),
        title: Text(
          guide.className,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${guide.shortDescription}\n키워드: ${guide.keywords.take(4).join(', ')}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          '/result',
          extra: ResultScreenData.manual(guide.classId, ''),
        ),
      ),
    );
  }
}
