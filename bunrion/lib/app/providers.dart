import 'package:bunrion/data/disposal_guide_repository.dart';
import 'package:bunrion/services/model/litert_waste_detector.dart';
import 'package:bunrion/services/model/waste_detector.dart';
import 'package:bunrion/services/storage/history_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final guideRepositoryProvider = Provider((ref) => DisposalGuideRepository());
final guidesProvider = FutureProvider(
  (ref) => ref.watch(guideRepositoryProvider).loadAll(),
);

final detectorProvider = Provider<WasteDetector>(
  (ref) => LiteRtWasteDetector(),
);
final modelAvailableProvider = FutureProvider(
  (ref) => ref.watch(detectorProvider).isModelAvailable(),
);

final sharedPreferencesProvider = FutureProvider(
  (ref) => SharedPreferences.getInstance(),
);

final historyStorageProvider = FutureProvider(
  (ref) async =>
      HistoryStorage(await ref.watch(sharedPreferencesProvider.future)),
);

final historyProvider = FutureProvider((ref) async {
  final storage = await ref.watch(historyStorageProvider.future);
  return storage.load();
});

final confidenceThresholdProvider =
    StateNotifierProvider<ConfidenceThresholdNotifier, double>(
      (ref) => ConfidenceThresholdNotifier(ref),
    );

class ConfidenceThresholdNotifier extends StateNotifier<double> {
  ConfidenceThresholdNotifier(this.ref) : super(0.45) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getDouble('confidenceThreshold') ?? 0.45;
  }

  Future<void> set(double value) async {
    final clamped = value.clamp(0.25, 0.80).toDouble();
    state = clamped;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble('confidenceThreshold', clamped);
  }
}
