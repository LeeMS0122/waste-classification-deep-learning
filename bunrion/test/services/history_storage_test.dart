import 'package:bunrion/services/storage/history_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('history saves and deletes locally', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = HistoryStorage(prefs);
    final item = HistoryItem(
      id: '1',
      imagePath: '/tmp/image.jpg',
      createdAt: DateTime(2026, 7, 29),
      classNames: const ['캔류'],
      topConfidence: 0.91,
      edited: false,
      detections: const [],
    );
    await storage.save(item);
    expect(storage.load(), hasLength(1));
    await storage.delete('1');
    expect(storage.load(), isEmpty);
  });
}
