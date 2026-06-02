import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart'; // 🔗 스마트폰 설정 딥링크 도구 연동

class SettingsScreen extends StatefulWidget {
  final bool isEnglish;

  const SettingsScreen({super.key, required this.isEnglish});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  bool _voiceNotify = true;
  late bool _currentLangIsEnglish;

  @override
  void initState() {
    super.initState();
    _currentLangIsEnglish = widget.isEnglish;
    _loadSyncSettings();
  }

  Future<void> _loadSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idController.text = prefs.getString('user_id') ?? "kpath_admin";
      _nameController.text = prefs.getString('user_name') ?? "강인구";
      _heightController.text = prefs.getString('user_height') ?? "175";
      _weightController.text = prefs.getString('user_weight') ?? "70";
      _voiceNotify = prefs.getBool('voice_notify') ?? true;
    });
  }

  Future<void> _saveSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _idController.text.trim());
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_height', _heightController.text.trim());
    await prefs.setString('user_weight', _weightController.text.trim());
    await prefs.setBool('voice_notify', _voiceNotify);
    await prefs.setBool('is_english', _currentLangIsEnglish);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_currentLangIsEnglish ? 'Settings Saved' : '모든 환경 설정이 영구 저장되었습니다.'))
      );
      Navigator.pop(context);
    }
  }

  // 🛠️ [★문법 오류 교정] 최신 패키지 규격 명칭인 AppSettingsType.settings로 전면 수정 완료
  void _openSmartphoneAppSettings() {
    try {
      AppSettings.openAppSettings(type: AppSettingsType.settings);
    } catch (e) {
      debugPrint("스마트폰 설정창 호출 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121224),
      appBar: AppBar(
        title: Text(_currentLangIsEnglish ? "K-Path Setup Menu" : "설정 및 시스템 관리"),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [1] 이용자 등록
            _buildSectionHeader(_currentLangIsEnglish ? "User Registration" : "이용자 등록"),
            const SizedBox(height: 12),
            _buildInputField(controller: _idController, label: _currentLangIsEnglish ? "ID" : "아이디"),
            const SizedBox(height: 12),
            _buildInputField(controller: _nameController, label: _currentLangIsEnglish ? "Name" : "이름"),
            const SizedBox(height: 12),
            _buildInputField(controller: _heightController, label: _currentLangIsEnglish ? "Height (cm)" : "신장 (cm)", isNumber: true),
            const SizedBox(height: 12),
            _buildInputField(controller: _weightController, label: _currentLangIsEnglish ? "Weight (kg)" : "체중 (kg)", isNumber: true),
            const SizedBox(height: 28),
            
            // [2] 알림설정
            _buildSectionHeader(_currentLangIsEnglish ? "Notification Settings" : "알림설정"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1A1A32), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: SwitchListTile(
                title: Text(_currentLangIsEnglish ? "500m Audio Notification" : "500미터 주행 정기 음성 알림", style: const TextStyle(color: Colors.white, fontSize: 15)),
                value: _voiceNotify,
                activeColor: Colors.cyanAccent,
                onChanged: (val) => setState(() => _voiceNotify = val),
              ),
            ),
            const SizedBox(height: 28),

            // [3] 언어설정
            _buildSectionHeader(_currentLangIsEnglish ? "Language Settings" : "언어설정"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1A1A32), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text("한국어 (Korean)", style: TextStyle(color: Colors.white)),
                    value: false,
                    groupValue: _currentLangIsEnglish,
                    activeColor: Colors.cyanAccent,
                    onChanged: (val) => setState(() => _currentLangIsEnglish = val!),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  RadioListTile<bool>(
                    title: const Text("English", style: TextStyle(color: Colors.white)),
                    value: true,
                    groupValue: _currentLangIsEnglish,
                    activeColor: Colors.cyanAccent,
                    onChanged: (val) => setState(() => _currentLangIsEnglish = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // K-Path 앱 설정 항목 ➡️ 스마트폰 기기 실제 설정 메뉴판 이식
            _buildSectionHeader(_currentLangIsEnglish ? "K-Path App Settings" : "K-Path 앱 설정 항목"),
            const SizedBox(height: 10),
            InkWell(
              onTap: _openSmartphoneAppSettings, 
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A32), 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.5), width: 1.5)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android_rounded, color: Colors.orangeAccent, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentLangIsEnglish ? "Open Smartphone App Settings" : "스마트폰 시스템 설정창 열기", 
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentLangIsEnglish ? "Manage GPS Permissions, Battery Optimization, etc." : "이곳을 누르면 기기 설정으로 이동하여 GPS 항상허용, 알림 등을 제어할 수 있습니다.", 
                            style: const TextStyle(color: Colors.white54, fontSize: 12)
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 앱 정보 디스플레이
            _buildSectionHeader(_currentLangIsEnglish ? "App System Info" : "K-Path 소프트웨어 시스템 정보"),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1A1A32), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("K-Path Professional", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${_currentLangIsEnglish ? "Version" : "버전 정보"}: 2026.06.03 (Latest)", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _saveSyncSettings,
                child: Text(_currentLangIsEnglish ? "SAVE CONFIGURATION" : "설정 완료 및 저장", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold));
  }

  Widget _buildInputField({required TextEditingController controller, required String label, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1A1A32),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent)),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}