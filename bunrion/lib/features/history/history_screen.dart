import 'dart:io';

import 'package:bunrion/app/providers.dart';
import 'package:bunrion/features/detection/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        actions: [
          IconButton(
            onPressed: () async {
              final storage = await ref.read(historyStorageProvider.future);
              await storage.clear();
              ref.invalidate(historyProvider);
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('저장된 기록을 불러오지 못했습니다.')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('기기에 저장된 인식 기록이 없습니다.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading:
                          item.imagePath.isNotEmpty &&
                              File(item.imagePath).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(item.imagePath),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.image_not_supported_outlined),
                      title: Text(item.classNames.join(', ')),
                      subtitle: Text(
                        '${item.createdAt.year}.${item.createdAt.month}.${item.createdAt.day} · 모델 신뢰도 ${(item.topConfidence * 100).toStringAsFixed(1)}%${item.edited ? ' · 수정됨' : ''}',
                      ),
                      onTap: () => context.push(
                        '/result',
                        extra: ResultScreenData(
                          imagePath: item.imagePath,
                          detections: item.detections,
                          edited: item.edited,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final storage = await ref.read(
                            historyStorageProvider.future,
                          );
                          await storage.delete(item.id);
                          ref.invalidate(historyProvider);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
