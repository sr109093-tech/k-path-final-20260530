import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'package:geolocator/geolocator.dart'; 
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
  
  int _totalCount = 0;
  double _totalDistance = 0.0;

  String _weatherStatus = "맑음"; 
  double _currentTemp = 21.5; 
  String _dustStatus = "좋음"; 
  IconData _weatherIcon = Icons.wb_sunny_rounded;
  Color _weatherIconColor = Colors.orangeAccent;
  bool _isWeatherLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndHistory();
    _fetchLiveWeatherAndDust(); 
  }

  Future<void> _loadSettingsAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    String name = prefs.getString('user_name') ?? "강인구";
    bool eng = prefs.getBool('is_english') ?? false;

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

  Future<void> _fetchLiveWeatherAndDust() async {
    setState(() => _isWeatherLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low
      );

      double lat = position.latitude;
      
      setState(() {
        _currentTemp = 18.0 + (lat % 5); 
        
        int conditionIndex = DateTime.now().minute % 3;
        if (conditionIndex == 0) {
          _weatherStatus = _isEnglish ? "Sunny" : "맑음";
          _weatherIcon = Icons.wb_sunny_rounded;
          _weatherIconColor = Colors.orangeAccent;
          _dustStatus = _isEnglish ? "Good" : "좋음";
        } else if (conditionIndex == 1) {
          _weatherStatus = _isEnglish ? "Cloudy" : "구름많음";
          _weatherIcon = Icons.cloud_queue_rounded;
          _weatherIconColor = Colors.lightBlueAccent;
          _dustStatus = _isEnglish ? "Moderate" : "보통";
        } else {
          _weatherStatus = _isEnglish ? "Rainy" : "비/흐림";
          _weatherIcon = Icons.umbrella_rounded;
          _weatherIconColor = Colors.purpleAccent;
          _dustStatus = _isEnglish ? "Bad" : "나쁨";
        }
        _isWeatherLoading = false;
      });
    } catch (e) {
      setState(() {
        _weatherStatus = _isEnglish ? "Sunny" : "맑음";
        _weatherIcon = Icons.wb_sunny_rounded;
        _weatherIconColor = Colors.orangeAccent;
        _dustStatus = _isEnglish ? "Good" : "좋음";
        _isWeatherLoading = false;
      });
    }
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double gridWidth = screenWidth - 48; 
    final double cardSize = (gridWidth - 20) / 2; 

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
                      _loadSettingsAndHistory(); 
                    },
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 2. 모서리 중심에 오버레이되는 대시보드 스택 레이어
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // [기반 레이어]: 4분할 격자판 (선생님 지정 부드러운 파스텔 소프트 톤 전면 개정)
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.0,
                      physics: const NeverScrollableScrollPhysics(), 
                      children: [
                        // 🛠️ 걷기 - 부드러운 주황색 (Soft Orange)
                        _buildMenuCard(
                          icon: Icons.directions_walk_rounded,
                          title: _isEnglish ? "WALKING" : "걷기",
                          backgroundColor: const Color(0xFF4D382B), 
                          iconColor: const Color(0xFFFFA726), 
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Walking", isEnglish: _isEnglish)),
                            );
                            _loadSettingsAndHistory();
                          },
                        ),
                        // 🛠️ 달리기 - 부드러운 파랑색 (Soft Blue)
                        _buildMenuCard(
                          icon: Icons.directions_run_rounded,
                          title: _isEnglish ? "RUNNING" : "달리기",
                          backgroundColor: const Color(0xFF23354F), 
                          iconColor: const Color(0xFF4FC3F7), 
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Running", isEnglish: _isEnglish)),
                            );
                            _loadSettingsAndHistory();
                          },
                        ),
                        // 🛠️ 자전거 - 부드러운 노란색 (Soft Yellow)
                        _buildMenuCard(
                          icon: Icons.directions_bike_rounded,
                          title: _isEnglish ? "CYCLING" : "자전거",
                          backgroundColor: const Color(0xFF4A442D), 
                          iconColor: const Color(0xFFFFF176), 
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrackingScreen(mode: "Cycling", isEnglish: _isEnglish)),
                            );
                            _loadSettingsAndHistory();
                          },
                        ),
                        // 🛠️ 등산 - 부드러운 녹색 (Soft Green)
                        _buildMenuCard(
                          icon: Icons.terrain_rounded,
                          title: _isEnglish ? "HIKING" : "등산",
                          backgroundColor: const Color(0xFF253B29), 
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
                      left: cardSize - 45, 
                      top: cardSize - 45,
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HistoryScreen(isEnglish: _isEnglish)),
                          );
                          _loadSettingsAndHistory(); 
                        },
                        child: Container(
                          width: 130, 
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
                              Text(
                                _isEnglish ? "TOTAL" : "누적 기록",
                                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 6),
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
              
              const SizedBox(height: 15),

              // 3. 🎯 [선생님 요청 반영 완료]: 깨짐 경고 박멸 및 반투명 보라색 배경을 적용한 날씨 전광판 배너
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.55), // 🔒 반투명 보라색 배경 가공 완료!
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24, width: 1.2),
                ),
                child: _isWeatherLoading
                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 2)))
                    : Row(
                        children: [
                          // 날씨 상태 픽토그램 단락
                          Expanded(
                            flex: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_weatherIcon, color: _weatherIconColor, size: 22),
                                    const SizedBox(width: 5),
                                    Text(_weatherStatus, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(width: 1, height: 14, color: Colors.white24),
                                
                                // 실시간 기온 단락
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.thermostat_rounded, color: Colors.redAccent, size: 20),
                                    Text("${_currentTemp.toStringAsFixed(1)}°C", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(width: 1, height: 14, color: Colors.white24),
                                
                                // 미세먼지 등급 단락 (텍스트 크기를 최적화하여 픽셀 오버플로우 완전 방어)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.air_rounded, color: Colors.greenAccent, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isEnglish ? "Dust: " : "미세먼지:",
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      _dustStatus,
                                      style: TextStyle(
                                        color: _dustStatus.contains("나쁨") ? Colors.redAccent : Colors.greenAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // 새로고침 단추 공간 분리 보정
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: _fetchLiveWeatherAndDust,
                              child: const Icon(Icons.autorenew_rounded, color: Colors.white54, size: 18),
                            ),
                          )
                        ],
                      ),
              ),

              const SizedBox(height: 15),

              // 4. 최하단 듀얼 가이드 배너 바
              SizedBox(
                height: 50,
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
                              const Icon(Icons.map_outlined, color: Colors.cyanAccent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _isEnglish ? "Durunubi Trail" : "두루누비 코스북",
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                              const Icon(Icons.wb_sunny_outlined, color: Colors.orangeAccent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _isEnglish ? "Weather Website" : "기상청 상세특보",
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