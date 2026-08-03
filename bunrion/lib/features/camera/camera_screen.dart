import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _loading = true;
  String? _error;
  XFile? _captured;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init([int cameraIndex = 0]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw StateError('사용 가능한 카메라가 없습니다.');
      await _controller?.dispose();
      _controller = CameraController(
        _cameras[cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _loading = false);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.code == 'CameraAccessDenied'
              ? '카메라 권한이 거부되었습니다. 설정에서 권한을 허용해 주세요.'
              : '카메라를 시작하지 못했습니다.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '카메라를 사용할 수 없습니다.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final file = await controller.takePicture();
    if (mounted) setState(() => _captured = file);
  }

  Future<void> _pickGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;
    context.push('/analysis', extra: image.path);
  }

  @override
  Widget build(BuildContext context) {
    if (_captured != null) {
      return _ConfirmPhoto(
        file: _captured!,
        onRetake: () => setState(() => _captured = null),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('촬영')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _CameraError(message: _error!, onRetry: () => _init())
          : Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 28,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          '쓰레기 전체가 보이도록 촬영해 주세요',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton.filledTonal(
                            onPressed: _pickGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                          ),
                          IconButton.filled(
                            onPressed: _takePicture,
                            iconSize: 42,
                            icon: const Icon(Icons.camera_alt),
                          ),
                          IconButton.filledTonal(
                            onPressed: _cameras.length < 2
                                ? null
                                : () {
                                    final current = _cameras.indexOf(
                                      _controller!.description,
                                    );
                                    _init((current + 1) % _cameras.length);
                                  },
                            icon: const Icon(Icons.cameraswitch_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ConfirmPhoto extends StatelessWidget {
  const _ConfirmPhoto({required this.file, required this.onRetake});

  final XFile file;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이미지 확인')),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(file.path),
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetake,
                    child: const Text('다시 찍기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        context.push('/analysis', extra: file.path),
                    child: const Text('이 사진 사용'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('재시도'),
            ),
          ],
        ),
      ),
    );
  }
}
