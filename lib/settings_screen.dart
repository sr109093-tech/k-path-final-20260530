import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  
  // 🎯 [요청 사항 반영]: 사용자 등록 창을 접고 펼치기 위한 제어 상태 변수
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
      debugPrint("프로필 이미지 선택 실패 방어: $e");
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
          content: Text(_isEnglishMode ? "Settings Applied Successfully!" : "설정이 안전하게 저장 및 적용되었습니다!"),
          backgroundColor: Colors.teal.shade700,
        ),
      );
      Navigator.pop(context);
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
      // 🎯 [1번 사진 가려짐 해결]: 전체를 ScrollView로 감싸 내비게이션 바 간섭 시 능동적으로 대피하게 구성
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 [요청 사항 반영]: 사용자 등록 헤더 버튼 인터페이스
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

            // 🎯 사용자 등록을 누르면 스르륵 열리는 입력창 섹션
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
                    // 📸 사진 등록 서브 아바타 섹션
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

            // 🔔 알림 설정 메뉴 섹션
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

            // 🌐 언어 설정 메뉴 섹션
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

            // 🎯 [요청 사항 반영]: 앱 기본설정 메뉴 신설 섹션
            _buildSectionHeader(_isEnglishMode ? "App Default Settings" : "앱 기본설정 메뉴"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Column(
                children: [
                  _buildSettingRow(Icons.gps_fixed_rounded, _isEnglishMode ? "GPS Update Interval" : "위성 수신 샘플링 주기", "1초 (고정)"),
                  const Divider(color: Colors.white10, height: 20),
                  _buildSettingRow(Icons.map_rounded, _isEnglishMode ? "Default Map Engine" : "기본 맵 엔진 드라이버", "OpenStreetMap"),
                  const Divider(color: Colors.white10, height: 20),
                  _buildSettingRow(Icons.backup_rounded, _isEnglishMode ? "Auto Data Backup" : "블랙박스 자동 백업 경로", "Download/k-path"),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // 🎯 [1번 사진 가려짐 완치부]: 하단 버튼 가려짐 현상을 위쪽 마진 패딩 구조로 완벽 밀어올림 처리
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
            // 최하단 소프트키 네비게이션 간섭을 완벽 분리 차단하는 무적 패딩 마진 버퍼
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
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        Text(value, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}