import 'dart:convert';
import 'dart:io';

import 'package:bunrion/data/disposal_guide_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disposal guide json has all seven classes and parses', () async {
    final file = File('assets/data/disposal_guides_ko.json');
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as List<dynamic>;
    final guides = decoded
        .map((item) => DisposalGuide.fromJson(item as Map<String, dynamic>))
        .toList();
    expect(guides.length, 7);
    expect(guides.map((item) => item.classId).toSet().length, 7);
    expect(
      guides.every((item) => item.steps.isNotEmpty && item.cautions.isNotEmpty),
      isTrue,
    );
  });
}
