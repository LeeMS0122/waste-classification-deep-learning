import 'dart:ui';

class LetterboxTransform {
  const LetterboxTransform({
    required this.scale,
    required this.dx,
    required this.dy,
    required this.inputSize,
  });

  final double scale;
  final double dx;
  final double dy;
  final double inputSize;

  Rect restore(Rect modelBox) => Rect.fromLTRB(
    ((modelBox.left - dx) / scale).clamp(0, double.infinity),
    ((modelBox.top - dy) / scale).clamp(0, double.infinity),
    ((modelBox.right - dx) / scale).clamp(0, double.infinity),
    ((modelBox.bottom - dy) / scale).clamp(0, double.infinity),
  );
}

LetterboxTransform letterboxFor({
  required double imageWidth,
  required double imageHeight,
  double inputSize = 640,
}) {
  final scale =
      inputSize / (imageWidth > imageHeight ? imageWidth : imageHeight);
  final resizedWidth = imageWidth * scale;
  final resizedHeight = imageHeight * scale;
  return LetterboxTransform(
    scale: scale,
    dx: (inputSize - resizedWidth) / 2,
    dy: (inputSize - resizedHeight) / 2,
    inputSize: inputSize,
  );
}
