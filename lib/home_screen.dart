import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔗 외부 날씨 및 사이트 링크 통로 도구
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

  // 🛠️ [★해결 핵심 3]: 외부 아웃도어 사이트 및 날씨 정보 연동 브라우저 소환 헬퍼
  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint("링크 연결 실패: $e");
    }
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
              // 1. 상단 타이틀바
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
              const SizedBox(height: 25),

              // 2. 중앙 4분할 격자 배치판 + 정중앙 누적 기록원
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.0,
                      children: [
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
                              BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 20, spreadRadius: 4)
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

              // 🛠️ [★해결 핵심 3]: 하단 자투리 공간에 배치한 두루누비 코스 탐방 및 기상청 날씨 조회 링크 바
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    // 왼쪽: 두루누비 링크 배너
                    Expanded(
                      child: InkWell(
                        onTap: () => _launchExternalUrl("https://www.durunubi.kr/"),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A32),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map_outlined, color: Colors.cyanAccent, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                _isEnglish ? "Durunubi Trail" : "두루누비 코스북",
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 오른쪽: 기상청 실시간 기상 날씨정보 링크 배너
                    Expanded(
                      child: InkWell(
                        onTap: () => _launchExternalUrl("https://www.weather.go.kr/w/index.do"),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A32),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wb_sunny_outlined, color: Colors.orangeAccent, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                _isEnglish ? "Weather Info" : "기상청 실시간 날씨",
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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