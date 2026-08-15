import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'tracking_screen.dart';
import 'history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Path',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1A1A2E),
        scaffoldBackgroundColor: const Color(0xFF11101D),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 🏠 [메인 화면 사령부 클래스]
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isEnglish = false;
  String _userName = "강인구";
  String? _profileImagePath;

  // 🎯 실시간 동적 누적 변수
  int _totalCount = 0;
  double _totalDistance = 0.0;

  // 실시간 날씨 데이터 상태 변수
  String _weatherStatus = "비/흐림";
  String _temperature = "20.5°C";
  String _airQuality = "보통";
  bool _isWeatherLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserConfig();
    _fetchWeatherData();
  }

  // 📊 [누적 기록 완전 복구 Engine]: 저장소 내 모든 가능한 Key와 JSON 형식을 전수 탐색
  Future<void> _loadUserConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 앱 내에서 사용 가능한 모든 기록 관련 Key 목록 전수 조사
    final possibleKeys = [
      'records',
      'history_list',
      'workout_records',
      'workout_history',
      'kpath_history'
    ];

    List<String> rawRecords = [];
    for (String key in possibleKeys) {
      List<String>? fetched = prefs.getStringList(key);
      if (fetched != null && fetched.isNotEmpty) {
        rawRecords.addAll(fetched);
      }
    }

    // 중복 데이터 제거 (동일한 JSON 문자열 중복 방지)
    rawRecords = rawRecords.toSet().toList();

    int count = rawRecords.length;
    double sumDist = 0.0;

    for (String item in rawRecords) {
      try {
        dynamic decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          dynamic distValue = decoded['distance'] ?? 
                              decoded['dist'] ?? 
                              decoded['totalDistance'] ?? 
                              decoded['distanceKm'];

          if (distValue != null) {
            if (distValue is num) {
              sumDist += distValue.toDouble();
            } else if (distValue is String) {
              sumDist += double.tryParse(distValue) ?? 0.0;
            }
          }
        }
      } catch (e) {
        debugPrint("기록 파싱 완치 예외 방어: $e");
      }
    }

    // 만약 파싱된 기록 목록이 없으나 별도 저장된 누적키가 존재하는 경우 백업 적용
    if (count == 0) {
      count = prefs.getInt('total_count') ?? prefs.getInt('workout_count') ?? 0;
      sumDist = prefs.getDouble('total_distance') ?? prefs.getDouble('workout_distance') ?? 0.0;
    }

    if (mounted) {
      setState(() {
        _isEnglish = prefs.getBool('is_english_mode') ?? false;
        _userName = prefs.getString('user_name') ?? "강인구";
        _profileImagePath = prefs.getString('profile_image_path');
        _totalCount = count;
        _totalDistance = double.parse(sumDist.toStringAsFixed(1));
      });
    }
  }

  // ⛅ Open-Meteo 실시간 공공 날씨 API 수신
  Future<void> _fetchWeatherData() async {
    setState(() => _isWeatherLoading = true);
    try {
      final weatherUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=37.5665&longitude=126.9780&current_weather=true'
      );
      final airUri = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=37.5665&longitude=126.9780&current=pm10,pm2_5'
      );

      final responseWeather = await http.get(weatherUri).timeout(const Duration(seconds: 5));
      final responseAir = await http.get(airUri).timeout(const Duration(seconds: 5));

      if (responseWeather.statusCode == 200) {
        final data = jsonDecode(responseWeather.body);
        double temp = data['current_weather']['temperature'] ?? 20.5;
        int weatherCode = data['current_weather']['weathercode'] ?? 0;

        String statusStr = "맑음";
        if (weatherCode >= 1 && weatherCode <= 3) statusStr = "구름조금";
        else if (weatherCode >= 45 && weatherCode <= 48) statusStr = "안개";
        else if (weatherCode >= 51 && weatherCode <= 67) statusStr = "비/흐림";
        else if (weatherCode >= 71) statusStr = "눈";

        _weatherStatus = statusStr;
        _temperature = "${temp.toStringAsFixed(1)}°C";
      }

      if (responseAir.statusCode == 200) {
        final airData = jsonDecode(responseAir.body);
        double pm10 = (airData['current']?['pm10'] ?? 30.0).toDouble();
        if (pm10 <= 30) _airQuality = _isEnglish ? "Good" : "좋음";
        else if (pm10 <= 80) _airQuality = _isEnglish ? "Normal" : "보통";
        else if (pm10 <= 150) _airQuality = _isEnglish ? "Poor" : "나쁨";
        else _airQuality = _isEnglish ? "Very Poor" : "매우나쁨";
      }
    } catch (e) {
      debugPrint("날씨 API 수신 예외 방어: $e");
    } finally {
      if (mounted) {
        setState(() => _isWeatherLoading = false);
      }
    }
  }

  // 🔗 외부 브라우저(두루누비 / 기상청) 웹사이트 연동
  Future<void> _launchWebUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("웹페이지 호출 예외 방어: $e");
    }
  }

  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          isEnglish: _isEnglish,
          onLanguageChanged: (bool newLang) {
            setState(() {
              _isEnglish = newLang;
            });
          },
        ),
      ),
    );
    _loadUserConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11101D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // 👑 상단 인사말 레이아웃 라인
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_profileImagePath != null && File(_profileImagePath!).existsSync()) ...[
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.cyanAccent,
                          backgroundImage: FileImage(File(_profileImagePath!)),
                        ),
                        const SizedBox(width: 10),
                      ] else ...[
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFF252545),
                          child: Icon(Icons.person_rounded, color: Colors.white38, size: 20),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        _isEnglish ? 'Welcome, $_userName' : '반갑습니다, $_userName 님',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.cyanAccent, size: 28),
                    onPressed: _navigateToSettings,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 📊 중앙 원형 누적 대시보드 및 4대 대형 운동 카드 섹션
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildModeCard('걷기', 'Walking', Icons.directions_walk_rounded, const Color(0xFFFFE0B2), const Color(0xFFE65100)),
                              const SizedBox(width: 16),
                              _buildModeCard('달리기', 'Running', Icons.directions_run_rounded, const Color(0xFFB3E5FC), const Color(0xFF01579B)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildModeCard('자전거', 'Cycling', Icons.directions_bike_rounded, const Color(0xFFFFF9C4), const Color(0xFFF57F17)),
                              const SizedBox(width: 16),
                              _buildModeCard('등산', 'Hiking', Icons.terrain_rounded, const Color(0xFFC8E6C9), const Color(0xFF1B5E20)),
                            ],
                          ),
                        ],
                      ),
                      
                      // 🎯 누적 기록 원형 디스크 (클릭 시 이력 화면 진입 및 다녀오면 자동 갱신)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HistoryScreen(isEnglish: _isEnglish)),
                          ).then((_) => _loadUserConfig());
                        },
                        child: Container(
                          width: 150, height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16162A),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)],
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.6), width: 3),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isEnglish ? 'Total' : '누적 기록', style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(
                                _isEnglish ? '≈ $_totalCount times' : '≈ $_totalCount회', 
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.analytics_rounded, color: Colors.white60, size: 14),
                                  const SizedBox(width: 4),
                                  Text('$_totalDistance km', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ⛅ 실시간 날씨 패널
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(color: Colors.purple.shade900.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.umbrella_rounded, color: Colors.purpleAccent, size: 18),
                            const SizedBox(width: 6),
                            Text(_weatherStatus, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            const Icon(Icons.device_thermostat_rounded, color: Colors.orangeAccent, size: 18),
                            Text(_temperature, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.air_rounded, color: Colors.tealAccent, size: 18),
                            Text(
                              _isEnglish ? ' Air: $_airQuality' : ' 미세먼지: $_airQuality', 
                              style: TextStyle(
                                color: _airQuality.contains('나쁨') ? Colors.orange : Colors.cyanAccent, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 13
                              )
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _fetchWeatherData,
                              child: _isWeatherLoading 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
                                  : const Icon(Icons.refresh_rounded, color: Colors.white60, size: 18),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A32), 
                            side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3))
                          ),
                          icon: const Icon(Icons.map, color: Colors.cyanAccent, size: 18),
                          label: Text(_isEnglish ? 'Durunubi' : '두루누비 코스북', style: const TextStyle(color: Colors.white)),
                          onPressed: () => _launchWebUrl('https://www.durunubi.kr'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A32), 
                            side: BorderSide(color: Colors.orangeAccent.withOpacity(0.3))
                          ),
                          icon: const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 18),
                          label: Text(_isEnglish ? 'KMA Weather' : '기상청 상세특보', style: const TextStyle(color: Colors.white)),
                          onPressed: () => _launchWebUrl('https://www.weather.go.kr'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(String koTitle, String enTitle, IconData icon, Color bg, Color textCo) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingScreen(mode: enTitle, isEnglish: _isEnglish),
          ),
        ).then((_) => _loadUserConfig());
      },
      child: Container(
        width: 140, height: 140,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textCo, size: 40),
            const SizedBox(height: 10),
            Text(_isEnglish ? enTitle : koTitle, style: TextStyle(color: textCo, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ⚙️ [환경설정 및 프로필 제어 서브 스크린 클래스]
class SettingsScreen extends StatefulWidget {
  final bool isEnglish;
  final Function(bool) onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.isEnglish,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  bool _isSpeechEnabled = true;
  bool _isEnglishMode = false;
  String? _profileImagePath;
  
  bool _showUserRegistration = false; 

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEnglishMode = widget.isEnglish;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? "강인구";
      _ageController.text = prefs.getString('user_age') ?? "66";
      _weightController.text = prefs.getString('user_weight') ?? "63";
      _isSpeechEnabled = prefs.getBool('is_speech_enabled') ?? true;
      _profileImagePath = prefs.getString('profile_image_path');
    });
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint("갤러리 프로필 인양 예외 방어: $e");
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_age', _ageController.text);
    await prefs.setString('user_weight', _weightController.text);
    await prefs.setBool('is_speech_enabled', _isSpeechEnabled);
    await prefs.setBool('is_english_mode', _isEnglishMode);
    
    if (_profileImagePath != null) {
      await prefs.setString('profile_image_path', _profileImagePath!);
    } else {
      await prefs.remove('profile_image_path');
    }

    widget.onLanguageChanged(_isEnglishMode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEnglishMode ? "Settings Saved Successfully!" : "설정이 안전하게 저장 및 동기화되었습니다!"),
          backgroundColor: Colors.teal.shade700,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _openAndroidAppSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      debugPrint("네이티브 설정 제어 센터 호출 예외 방어: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11101D),
      appBar: AppBar(
        title: Text(
          _isEnglishMode ? 'User Registration & Settings' : '사용자 등록 및 환경 설정',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Colors.cyanAccent),
            onPressed: _saveSettings,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFF1A1A32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.account_box_rounded, color: Colors.cyanAccent, size: 30),
                title: Text(
                  _isEnglishMode ? "User Profile Registration" : "사용자 프로필 등록 / 수정",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(
                  _showUserRegistration ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: Colors.white70,
                ),
                onTap: () {
                  setState(() {
                    _showUserRegistration = !_showUserRegistration;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            if (_showUserRegistration) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF252545),
                            backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                            child: _profileImagePath == null
                                ? const Icon(Icons.person_rounded, size: 50, color: Colors.white38)
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.cyanAccent,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                                onPressed: _pickProfileImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel(_isEnglishMode ? "Name" : "이름"),
                    _buildTextField(_nameController, Icons.person, _isEnglishMode ? "Enter name" : "이름을 입력하세요"),
                    const SizedBox(height: 14),

                    _buildLabel(_isEnglishMode ? "Age" : "나이"),
                    _buildTextField(_ageController, Icons.calendar_month, _isEnglishMode ? "Enter age" : "나이를 입력하세요", isNumber: true),
                    const SizedBox(height: 14),

                    _buildLabel(_isEnglishMode ? "Weight (kg)" : "체중 (kg)"),
                    _buildTextField(_weightController, Icons.monitor_weight, _isEnglishMode ? "Enter weight" : "체중을 입력하세요", isNumber: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildSectionHeader(_isEnglishMode ? "Notification Settings" : "알림 설정"),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                activeColor: Colors.cyanAccent,
                title: Text(_isEnglishMode ? "Real-time Voice Guidance" : "실시간 음성 알림 가동", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(
                  _isEnglishMode ? "Toggle voice tracking prompts." : "주행 안내 및 종료 격려 소리를 켜거나 끕니다.",
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                value: _isSpeechEnabled,
                onChanged: (bool val) => setState(() => _isSpeechEnabled = val),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(_isEnglishMode ? "Language Settings" : "언어 설정"),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                activeColor: Colors.cyanAccent,
                title: Text(_isEnglishMode ? "Use English Interface" : "영문 모드 인터페이스 사용", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(
                  _isEnglishMode ? "Switch main screen language to English." : "앱 전반의 시스템 언어를 영문 레이아웃으로 변경합니다.",
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                value: _isEnglishMode,
                onChanged: (bool val) => setState(() => _isEnglishMode = val),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(_isEnglishMode ? "App Default Settings" : "앱 기본설정 메뉴"),
            InkWell(
              onTap: _openAndroidAppSettings,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    _buildSettingRow(Icons.gps_fixed_rounded, _isEnglishMode ? "GPS Interval" : "위성 수신 샘플링 주기", "1초 (고정)"),
                    const Divider(color: Colors.white10, height: 20),
                    _buildSettingRow(Icons.map_rounded, _isEnglishMode ? "Map Engine" : "기본 맵 엔진 드라이버", "OpenStreetMap"),
                    const Divider(color: Colors.white10, height: 20),
                    _buildSettingRow(Icons.backup_rounded, _isEnglishMode ? "Data Backup" : "블랙박스 자동 백업 경로", "Download/k-path"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 35),

            Center(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.black, size: 20),
                  label: Text(
                    _isEnglishMode ? "Apply & Complete" : "설정 완료 및 적용",
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _saveSettings,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1E1E38),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label, 
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}