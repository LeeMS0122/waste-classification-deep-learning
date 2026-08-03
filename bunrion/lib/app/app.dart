import 'package:bunrion/app/router.dart';
import 'package:bunrion/app/theme.dart';
import 'package:flutter/material.dart';

class BunrionApp extends StatelessWidget {
  const BunrionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '분리ON',
      theme: BunrionTheme.light(),
      darkTheme: BunrionTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
