import 'package:bunrion/features/detection/result_screen.dart';
import 'package:bunrion/services/model/detection_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('no detection result shows unsupported guidance', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResultScreen(
            data: ResultScreenData(imagePath: '', detections: []),
          ),
        ),
      ),
    );
    expect(find.textContaining('지원하지 않는 품목'), findsOneWidget);
  });

  testWidgets('low confidence result is labeled as expected result', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ResultScreen(
            data: ResultScreenData(
              imagePath: '',
              detections: [
                DetectionResult(
                  classId: 0,
                  confidence: 0.30,
                  boundingBox: Rect.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('예상 결과'), findsOneWidget);
  });
}
