import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // 장부 데이터 분석용 도구
import 'package:url_launcher/url_launcher.dart'; 
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
  
  // 실시간 누적 성적표를 담기 위한 변수
  int _totalCount = 0;
  double _totalDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndHistory();
  }

  // 시스템 설정 및 누적 주행 거리/횟수를 실시간으로 계산하여 원 위에 뿌려주는 핵심 엔진
  Future<void> _loadSettingsAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. 기본 설정 로드
    String name = prefs.getString('user_name') ?? "강인구";
    bool eng = prefs.getBool('is_english') ?? false;

    // 2. 과거 장부 싹 긁어모으기
    List<String> historyList = prefs.getStringList('workout_history') ?? [];
    int count = historyList.length;
    double distanceSum = 0.0;

    for (String recordStr in historyList) {
      try {
        Map<String, dynamic> record = jsonDecode(recordStr);
        if (record['distance'] != null) {
          distanceSum += (record['distance'] as num).toDouble();
        }
      } catch (e) {
        debugPrint("장부 판독 오류 방어: $e");
      }
    }

    setState(() {
      _userName = name;
      _isEnglish = eng;
      _totalCount = count;
      _totalDistance = distanceSum;
    });
  }

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
    // 화면 크기를 실시간으로 계산하여 정확한 모서리 교차점 중앙을 물리적으로 잡아냅니다.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double gridWidth = screenWidth - 48; // 전체 패딩 24 * 2 제외
    final double cardSize = (gridWidth - 20) / 2; // 간격 20 제외한 순수 카드 가로폭

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
                      _loadSettingsAndHistory(); // 설정 변경 후 복귀 시 재동기화
                    },
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 2. 모서리 중심에 칼같이 오버레이되는 대시보드 스택 레이어
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // [기반 레이어]: 4분할 격자판 (부드러운 파스텔 다크 색감 튜닝)
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.0,
                      physics: const NeverScrollableScrollPhysics(), // 정렬 흐트러짐 방지 락
                      children: [
                        // 걷기 - 부드러운 소프트 레드 톤
                        _buildMenuCard(
                          icon: Icons.directions_walk_rounded,
                          title: _isEnglish ? "WALKING" : "걷기",
                          backgroundColor: const Color(0xFF4A2828), 
                          iconColor: const Color(0xFFE57373), // 🛠️ 오타 오염물질 완벽 세척 완료!
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Walking", isEnglish: _isEnglish)),
                            );
                            _loadSettingsAndHistory();
                          },
                        ),
                        // 달리기 - 부드러운 소프트 블루 톤
                        _buildMenuCard(
                          icon: Icons.directions_run_rounded,
                          title: _isEnglish ? "RUNNING" : "달리기",
                          backgroundColor: const Color(0xFF283A55), 
                          iconColor: const Color(0xFF64B5F6),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Running", isEnglish: _isEnglish)),
                            );
                            _loadSettingsAndHistory();
                          },
                        ),
                        // 자전거 - 부드러운 소프트 앰버 오렌지 톤
                        _buildMenuCard(
                          icon: Icons.directions_bike_rounded,
                          title: _isEnglish ? "CYCLING" : "자전거",
                          backgroundColor: const Color(0xFF4D3B2B), 
                          iconColor: const Color(0xFFFFB74D),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Cycling", isEnglish: _isEnglish)),
                            );
                            _loadSettingsAndHistory();
                          },
                        ),
                        // 등산 - 부드러운 소프트 숲속 그린 톤
                        _buildMenuCard(
                          icon: Icons.terrain_rounded,
                          title: _isEnglish ? "HIKING" : "등산",
                          backgroundColor: const Color(0xFF2A3E2C), 
                          iconColor: const Color(0xFF81C784),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Hiking", isEnglish: _isEnglish)),
                            );
                            _loadSettingsAndHistory();
                          },
                        ),
                      ],
                    ),

                    // 4개 종목의 모서리가 크로스되는 정확한 '정중앙 물리 좌표' 고정 배치
                    Positioned(
                      left: cardSize - 45, // 카드가 끝나는 정중앙 경계선 마진 연산 오프셋
                      top: cardSize - 45,
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HistoryScreen(isEnglish: _isEnglish)),
                          );
                          _loadSettingsAndHistory(); // 기록 확인 후 돌아올 때 새로고침
                        },
                        child: Container(
                          width: 130, // 수치 가독성 공간 확보를 위해 지름 확장
                          height: 130,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E38),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.45),
                                blurRadius: 22,
                                spreadRadius: 4,
                              )
                            ],
                            border: Border.all(color: Colors.cyanAccent, width: 3),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 상단: 타이틀
                              Text(
                                _isEnglish ? "TOTAL" : "누적 기록",
                                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 6),
                              
                              // 중앙: 누적 운동 횟수 (실시간)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.stacked_line_chart_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    "$_totalCount${_isEnglish ? ' Dynamic' : '회'}",
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              
                              // 하단: 누적 주행 거리 (실시간)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.space_dashboard_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    "${_totalDistance.toStringAsFixed(1)} km",
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
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

              // 3. 하단 자투리 공간 브라우저 연동 배너 팩
              Expanded(
                flex: 1,
                child: Row(
                  children: [
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
          border: Border.all(color: Colors.white12, width: 1.5),
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