import 'dart:convert';

import 'package:flutter/services.dart';

class DisposalGuide {
  const DisposalGuide({
    required this.classId,
    required this.className,
    required this.shortDescription,
    required this.steps,
    required this.cautions,
    required this.keywords,
    required this.officialSourceUrl,
    required this.regionalNotice,
  });

  final int classId;
  final String className;
  final String shortDescription;
  final List<String> steps;
  final List<String> cautions;
  final List<String> keywords;
  final String officialSourceUrl;
  final String regionalNotice;

  factory DisposalGuide.fromJson(Map<String, dynamic> json) => DisposalGuide(
    classId: json['classId'] as int,
    className: json['className'] as String,
    shortDescription: json['shortDescription'] as String,
    steps: List<String>.from(json['steps'] as List),
    cautions: List<String>.from(json['cautions'] as List),
    keywords: List<String>.from(json['keywords'] as List),
    officialSourceUrl: json['officialSourceUrl'] as String,
    regionalNotice: json['regionalNotice'] as String,
  );
}

class DisposalGuideRepository {
  Future<List<DisposalGuide>> loadAll() async {
    final raw = await rootBundle.loadString(
      'assets/data/disposal_guides_ko.json',
    );
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => DisposalGuide.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DisposalGuide?> findByClassId(int classId) async {
    final guides = await loadAll();
    for (final guide in guides) {
      if (guide.classId == classId) return guide;
    }
    return null;
  }

  Future<List<DisposalGuide>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final guides = await loadAll();
    if (normalized.isEmpty) return guides;
    return guides
        .where(
          (guide) =>
              guide.className.toLowerCase().contains(normalized) ||
              guide.keywords.any(
                (keyword) => keyword.toLowerCase().contains(normalized),
              ),
        )
        .toList();
  }
}
