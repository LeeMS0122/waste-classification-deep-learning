import 'dart:convert';
import 'dart:ui';

import 'package:bunrion/core/constants/waste_classes.dart';
import 'package:bunrion/services/model/detection_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    required this.classNames,
    required this.topConfidence,
    required this.edited,
    required this.detections,
  });

  final String id;
  final String imagePath;
  final DateTime createdAt;
  final List<String> classNames;
  final double topConfidence;
  final bool edited;
  final List<DetectionResult> detections;

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
    'classNames': classNames,
    'topConfidence': topConfidence,
    'edited': edited,
    'detections': detections.map((item) => item.toJson()).toList(),
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final classNames = List<String>.from(json['classNames'] as List);
    final rawDetections = json['detections'] as List<dynamic>?;
    final detections = rawDetections == null
        ? classNames
              .map(
                (name) => DetectionResult(
                  classId: WasteClasses.idOf(name) ?? -1,
                  confidence: (json['topConfidence'] as num).toDouble(),
                  boundingBox: Rect.zero,
                ),
              )
              .toList()
        : rawDetections
              .map(
                (item) =>
                    DetectionResult.fromJson(item as Map<String, dynamic>),
              )
              .toList();

    return HistoryItem(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      classNames: classNames,
      topConfidence: (json['topConfidence'] as num).toDouble(),
      edited: json['edited'] as bool,
      detections: detections,
    );
  }
}

class HistoryStorage {
  HistoryStorage(this.prefs);

  static const key = 'recognitionHistory';
  final SharedPreferences prefs;

  List<HistoryItem> load() {
    final raw = prefs.getStringList(key) ?? const [];
    return raw
        .map(
          (item) =>
              HistoryItem.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(HistoryItem item) async {
    final items = [item, ...load().where((old) => old.id != item.id)].take(50);
    await prefs.setStringList(
      key,
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> delete(String id) async {
    await prefs.setStringList(
      key,
      load()
          .where((item) => item.id != id)
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }

  Future<void> clear() => prefs.remove(key);
}
