import 'package:flutter/material.dart';
import 'tracking_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  final bool isEnglish;

  const ModeSelectionScreen({
    super.key, 
    required this.isEnglish,
  });

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  void _loadData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121224),
      appBar: AppBar(
        title: Text(widget.isEnglish ? "Select Mode" : "운동 모드 선택"),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Stack( // 🛠️ Expanded 충돌을 피하기 위해 확실한 위치 레이아웃인 Stack 구조로 전면 개정
            children: [
              // 중앙 운동 종목 콘텐츠 배치 영역
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        widget.isEnglish ? "Choose your activity" : "원하시는 운동 종목을 선택하세요",
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 35),
                      _buildModeButton(
                        context, 
                        icon: Icons.directions_walk_rounded, 
                        title: widget.isEnglish ? "Walking" : "걷기", 
                        modeKey: "Walking"
                      ),
                      const SizedBox(height: 16),
                      _buildModeButton(
                        context, 
                        icon: Icons.directions_run_rounded, 
                        title: widget.isEnglish ? "Running" : "달리기", 
                        modeKey: "Running"
                      ),
                      const SizedBox(height: 16),
                      _buildModeButton(
                        context, 
                        icon: Icons.directions_bike_rounded, 
                        title: widget.isEnglish ? "Cycling" : "자전거", 
                        modeKey: "Cycling"
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 듀얼 탭 고정 레이어 (마진 꼬임 방지 락 장치)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A32),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.history_rounded, color: Colors.cyanAccent),
                          label: Text(
                            widget.isEnglish ? "History" : "기록보기", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                          onPressed: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (c) => HistoryScreen(isEnglish: widget.isEnglish))
                            ).then((_) => _loadData());
                          },
                        ),
                      ),
                      Container(width: 1, height: 24, color: Colors.white12),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.tune_rounded, color: Colors.orangeAccent),
                          label: Text(
                            widget.isEnglish ? "Settings" : "설정변경", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (c) => SettingsScreen(isEnglish: widget.isEnglish))
                            );
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, {
    required IconData icon,
    required String title,
    required String modeKey,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackingScreen(
              mode: modeKey,
              isEnglish: widget.isEnglish,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A32),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 30),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }
}