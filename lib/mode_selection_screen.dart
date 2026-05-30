import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setting_screen.dart';
import 'tracking_screen.dart';
import 'history_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});
  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  String _lang = '한국어';
  String _totalDist = "0.00";
  int _workoutCount = 0;
  String? _profilePath;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList('workouts') ?? [];
    setState(() {
      _lang = prefs.getString('language') ?? '한국어';
      _totalDist = prefs.getString('total_distance') ?? "0.00";
      _workoutCount = records.length; // ✅ 누적 운동 횟수
      _profilePath = prefs.getString('userProfilePath'); // ✅ 사용자 사진
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = _lang == 'English';
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 📊 4분할 레이아웃
            Column(
              children: [
                Expanded(child: Row(children: [_tile(context, isEn ? 'Walking' : '걷기', const Color(0xFF1976D2), Icons.directions_walk, isEn), _tile(context, isEn ? 'Hiking' : '등산', const Color(0xFFD32F2F), Icons.terrain, isEn)])),
                Expanded(child: Row(children: [_tile(context, isEn ? 'Running' : '달리기', const Color(0xFF7B1FA2), Icons.directions_run, isEn), _tile(context, isEn ? 'Cycling' : '자전거', const Color(0xFFEF6C00), Icons.directions_bike, isEn)])),
              ],
            ),
            
            // ⚪ [수정] 중앙 원: 날씨, 거리, 횟수 통합
            Center(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HistoryScreen())).then((_) => _loadData()),
                child: Container(
                  width: 175, height: 175,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle, 
                    border: Border.all(color: const Color(0xFFFFBF00), width: 8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)]
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.wb_sunny, size: 16, color: Colors.orange), SizedBox(width: 4), Text("22°C", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 8),
                      Text("$_totalDist km", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Color(0xFFB8860B))),
                      const SizedBox(height: 5),
                      Text(isEn ? '$_workoutCount Workouts' : '누적 $_workoutCount회', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            
            // 🌤 좌측 상단 날씨 요약
            Positioned(top: 25, left: 20, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)), child: const Text("맑음", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),

            // ⚙ [수정] 우측 상단 사용자 사진 + 설정 아이콘
            Positioned(
              top: 15, right: 15, 
              child: Row(
                children: [
                  // ✅ 사용자 프로필 사진 (설정 버튼과 같은 크기)
                  Container(
                    width: 45, height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white24, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: _profilePath != null ? DecorationImage(image: FileImage(File(_profilePath!)), fit: BoxFit.cover) : null,
                    ),
                    child: _profilePath == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  // 설정 아이콘
                  Container(
                    width: 45, height: 45,
                    decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                    child: IconButton(icon: const Icon(Icons.settings, size: 28, color: Colors.white), onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingScreen()));
                      _loadData();
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String title, Color color, IconData icon, bool isEn) => Expanded(
    child: GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TrackingScreen(mode: title, isEnglish: isEn))).then((_) => _loadData()),
      child: Container(color: color, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 60, color: Colors.white70), const SizedBox(height: 10), Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))])),
    ),
  );
}