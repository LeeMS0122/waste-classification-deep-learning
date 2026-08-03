import 'package:bunrion/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(modelAvailableProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.recycling,
                  size: 86,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  '분리ON',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '사진 한 장으로 확인하는 올바른 분리배출',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                available.when(
                  loading: () => const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('모델 로딩 상태를 확인하고 있어요'),
                    ],
                  ),
                  error: (error, _) => _ErrorBlock(
                    message: '모델 상태 확인에 실패했습니다.',
                    onRetry: () => ref.invalidate(modelAvailableProvider),
                  ),
                  data: (ok) => Column(
                    children: [
                      Icon(
                        ok ? Icons.check_circle : Icons.info_outline,
                        color: ok ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ok
                            ? '온디바이스 모델을 사용할 수 있습니다.'
                            : '모델 파일이 아직 없습니다. 직접 선택 안내는 사용할 수 있습니다.',
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.go('/'),
                        child: const Text('시작하기'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('재시도'),
        ),
      ],
    );
  }
}
