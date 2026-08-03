import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class PreparedImage {
  const PreparedImage({required this.path, required this.bytes});

  final String path;
  final List<int> bytes;
}

Future<PreparedImage> prepareImageForInference(String sourcePath) async {
  final sourceBytes = await File(sourcePath).readAsBytes();
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    throw const FormatException('지원하지 않는 이미지 형식입니다.');
  }

  final oriented = img.bakeOrientation(decoded);
  final longestSide = max(oriented.width, oriented.height);
  final resized = longestSide > 1600
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 1600 : null,
          height: oriented.height > oriented.width ? 1600 : null,
          interpolation: img.Interpolation.average,
        )
      : oriented;

  final jpgBytes = img.encodeJpg(resized, quality: 92);
  final tempDir = await getTemporaryDirectory();
  final file = File(
    '${tempDir.path}/bunrion_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(jpgBytes, flush: true);
  return PreparedImage(path: file.path, bytes: jpgBytes);
}
