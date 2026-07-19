import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// 🛠️ [시스템 설정창 개통]: 1번 사진의 탭을 누르면 2번 스마트폰 시스템 애플리케이션 정보창이 즉시 뜨도록 돕는 플러그인
import 'package:app_settings/app_settings.dart';
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

  // 기존 누적 스태츠 데이터 로직 무결점 보존
  final int _totalCount = 77;
  final double _totalDistance = 59.9;

  @override
  void initState() {
    super.initState();
    _loadUserConfig();
  }

  Future<void> _loadUserConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnglish = prefs.getBool('is_english_mode') ?? false;
      _userName = prefs.getString('user_name') ?? "강인구";
      _profileImagePath = prefs.getString('profile_image_path');
    });
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
    _loadUserConfig(); // 설정창 다녀오면 프로필 사진과 한글/영문 최신 상태 동기화
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
                  // 프로필 사진 등록 시 인사말 옆에 동그랗고 예쁜 원형 액자 표출
                  Row(
                    children: [
                      if (_profileImagePath != null && File(_profileImagePath!).existsSync()) ...[
                        CircleAvatar(
                          radius: 20, // 인삿말 크기 축소에 맞춰 액자도 조화롭게 세련된 크기로 조율
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
                      // 🎯 [요청 사항 반영]: 기존 22 크기에서 작고 정갈한 18 크기로 축소 완료
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
                      
                      // 🎯 [요청 사항 반영]: 누적 기록 디스크 탭을 누르면 역사적인 운동기록 화면으로 진입하도록 개통 완료
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
                              Text('≈ $_totalCount${_isEnglish ? '次' : '회'}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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

              // ⛅ 최하단 공공 날씨 패널 및 서브 링크 버튼 라인 (기존 소스 무결점 보존)
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
                            Text(_isEnglish ? 'Rain/Cloudy' : '비/흐림', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            const Icon(Icons.device_thermostat_rounded, color: Colors.orangeAccent, size: 18),
                            Text('20.5°C', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.air_rounded, color: Colors.tealAccent, size: 18),
                            Text(_isEnglish ? ' Air: Poor' : ' 미세먼지: 나쁨', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 6),
                            const Icon(Icons.refresh_rounded, color: Colors.white60, size: 16),
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
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A32), side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3))),
                          icon: const Icon(Icons.map, color: Colors.cyanAccent, size: 18),
                          label: Text(_isEnglish ? 'Durunubi' : '두루누비 코스북', style: const TextStyle(color: Colors.white)),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A32), side: BorderSide(color: Colors.orangeAccent.withOpacity(0.3))),
                          icon: const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 18),
                          label: Text(_isEnglish ? 'KMA Weather' : '기상청 상세특보', style: const TextStyle(color: Colors.white)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(isEnglish: _isEnglish))),
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

  // 🛠️ 스마트폰 시스템 설정 페이지(2번 사진 화면)를 다이렉트로 개방하는 기능 구현
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
          crossAxisAlignment: CrossAxisAlignment.start, // 🛠️ [문법 완치]: 구조를 깨뜨리던 이물질 오타 전면 축출 완료
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

            // 🎯 누르면 2번 사진인 안드로이드 애플리케이션 정보창이 바로 뜨는 탭 버튼
            _buildSectionHeader(_isEnglishMode ? "App Default Settings" : "앱 기본설정 메뉴"),
            InkWell(
              onTap: _openAndroidAppSettings, // 누르면 2번 화면으로 다이렉트 도약 점프
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1), // 터치 버튼임을 고지하는 밝은 테두리 마감
                ),
                child: Column(
                  children: [
                    // 🛠️ FittedBox 장착으로 1번 사진 우측 글자가 잘려 노란 검정 빗금 에러 배너가 터지던 레이아웃 버그 완치
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

  // 글자 넘침 버그를 철통 방어하기 위해 내부 정밀 FittedBox 캡슐 마감
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