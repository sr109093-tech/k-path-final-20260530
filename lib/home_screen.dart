import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tracking_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEnglish = false;
  String _userName = "강인구";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnglish = prefs.getBool('is_english') ?? false;
      _userName = prefs.getString('user_name') ?? "강인구";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121224),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 타이틀바 (우측에 톱니바퀴 설정 버튼 노출)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEnglish ? "Welcome, $_userName" : "반갑습니다, $_userName 님",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.cyanAccent, size: 28),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SettingsScreen(isEnglish: _isEnglish)),
                      );
                      _loadSettings();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 2. 🎯 [선생님의 아이덴티티]: 4종목 한가운데 완벽하게 정렬된 누적 기록 원형 레이아웃
              Expanded(
                child: Stack(
                  children: [
                    // 외곽 4분할 격자 배치판
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.0,
                      children: [
                        // [1번 방: 걷기 - 빨강색 바탕]
                        _buildMenuCard(
                          icon: Icons.directions_walk_rounded,
                          title: _isEnglish ? "WALKING" : "걷기",
                          backgroundColor: Colors.red.shade900.withOpacity(0.85),
                          iconColor: Colors.redAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Walking", isEnglish: _isEnglish)),
                            );
                          },
                        ),
                        // [2번 방: 달리기 - 파랑색 바탕]
                        _buildMenuCard(
                          icon: Icons.directions_run_rounded,
                          title: _isEnglish ? "RUNNING" : "달리기",
                          backgroundColor: Colors.blue.shade900.withOpacity(0.85),
                          iconColor: Colors.blueAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Running", isEnglish: _isEnglish)),
                            );
                          },
                        ),
                        // [3번 방: 자전거 - 노랑색 바탕]
                        _buildMenuCard(
                          icon: Icons.directions_bike_rounded,
                          title: _isEnglish ? "CYCLING" : "자전거",
                          backgroundColor: Colors.amber.shade900.withOpacity(0.85),
                          iconColor: Colors.amberAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Cycling", isEnglish: _isEnglish)),
                            );
                          },
                        ),
                        // [4번 방: 등산 - 녹색 바탕]
                        _buildMenuCard(
                          icon: Icons.terrain_rounded,
                          title: _isEnglish ? "HIKING" : "등산",
                          backgroundColor: Colors.green.shade900.withOpacity(0.85),
                          iconColor: Colors.greenAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Hiking", isEnglish: _isEnglish)),
                            );
                          },
                        ),
                      ],
                    ),

                    // 🎯 종목 정보 4개의 정중앙에 완벽하게 오버레이되는 [누적 기록] 센터 원
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HistoryScreen(isEnglish: _isEnglish)),
                          );
                        },
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A32),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 4,
                              )
                            ],
                            border: Border.all(color: Colors.cyanAccent, width: 3),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_toggle_off_rounded, color: Colors.cyanAccent, size: 34),
                              const SizedBox(height: 6),
                              Text(
                                _isEnglish ? "HISTORY" : "누적 기록",
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [
                Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 4),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}