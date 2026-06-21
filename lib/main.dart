import 'package:flutter/material.dart';
import 'home_screen.dart'; // 🔗 증발했던 화사한 4분할 홈 화면 모듈 완벽 복원 결합

void main() {
  runApp(const KPathApp());
}

class KPathApp extends StatelessWidget {
  const KPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Path',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF121224),
      ),
      // 🎯 [완벽한 복구 핵심]: 지도로 곧바로 열리던 엉망인 구조를 파괴하고, 
      // 원래 약속되었던 정갈한 4분할 대시보드 화면(HomeScreen)을 첫 관문으로 재설정했습니다.
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}