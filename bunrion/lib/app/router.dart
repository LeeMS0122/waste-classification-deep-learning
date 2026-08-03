import 'package:bunrion/features/camera/camera_screen.dart';
import 'package:bunrion/features/detection/analysis_screen.dart';
import 'package:bunrion/features/detection/result_screen.dart';
import 'package:bunrion/features/dictionary/dictionary_screen.dart';
import 'package:bunrion/features/history/history_screen.dart';
import 'package:bunrion/features/home/home_screen.dart';
import 'package:bunrion/features/live_detection/live_detection_screen.dart';
import 'package:bunrion/features/settings/settings_screen.dart';
import 'package:bunrion/features/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/camera',
          builder: (context, state) => const CameraScreen(),
        ),
        GoRoute(
          path: '/dictionary',
          builder: (context, state) => const DictionaryScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/analysis',
      builder: (context, state) =>
          AnalysisScreen(imagePath: state.extra! as String),
    ),
    GoRoute(
      path: '/live-detection',
      builder: (context, state) => const LiveDetectionScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) =>
          ResultScreen(data: state.extra! as ResultScreenData),
    ),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final index = switch (location) {
      '/camera' => 1,
      '/dictionary' => 2,
      '/history' => 3,
      _ => 0,
    };
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          final target = ['/', '/camera', '/dictionary', '/history'][value];
          context.go(target);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            selectedIcon: Icon(Icons.photo_camera),
            label: '촬영',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '품목사전',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '기록',
          ),
        ],
      ),
    );
  }
}
