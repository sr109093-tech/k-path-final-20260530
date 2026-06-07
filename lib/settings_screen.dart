import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final bool isEnglish;

  const SettingsScreen({super.key, required this.isEnglish});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isEnglish = false;
  bool _isSpeechEnabled = true;
  double _speechVolume = 1.0; 

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEnglish = widget.isEnglish;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSpeechEnabled = prefs.getBool('is_speech_enabled') ?? true;
      _isEnglish = prefs.getBool('is_english') ?? widget.isEnglish;
      _speechVolume = prefs.getDouble('speech_volume') ?? 1.0; 
      
      _idController.text = prefs.getString('user_id') ?? "";
      _nameController.text = prefs.getString('user_name') ?? "강인구";
      _ageController.text = prefs.getString('user_age') ?? "";
      _weightController.text = prefs.getString('user_weight') ?? "";
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('user_id', _idController.text.trim());
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_age', _ageController.text.trim());
    await prefs.setString('user_weight', _weightController.text.trim());
    
    await prefs.setBool('is_speech_enabled', _isSpeechEnabled);
    await prefs.setBool('is_english', _isEnglish);
    await prefs.setDouble('speech_volume', _speechVolume); 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEnglish ? 'Settings saved!' : '사용자 정보 및 환경 설정이 안전하게 저장되었습니다.'),
          backgroundColor: Colors.cyan.shade700,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121224),
      appBar: AppBar(
        title: Text(_isEnglish ? 'Settings' : '사용자 등록 및 환경 설정'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Colors.cyanAccent, size: 26),
            onPressed: _saveSettings,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🛠️ [명칭 전면 개정 1]: "사용자 프로필 정보등록" ➡️ "사용자 등록" 변경 완료
            Text(_isEnglish ? "User Registration" : "사용자 등록", style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1A1A32), borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  _buildProfileTextField(
                    controller: _idController,
                    label: _isEnglish ? "User ID" : "사용자 아이디",
                    hint: _isEnglish ? "Enter ID" : "아이디를 입력하세요",
                    icon: Icons.account_box_rounded,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildProfileTextField(
                    controller: _nameController,
                    label: _isEnglish ? "Name" : "이름",
                    hint: _isEnglish ? "Enter name" : "이름을 입력하세요",
                    icon: Icons.person_rounded,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildProfileTextField(
                    controller: _ageController,
                    label: _isEnglish ? "Age" : "나이",
                    hint: _isEnglish ? "Enter age" : "나이를 입력하세요 (세)",
                    icon: Icons.calendar_today_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildProfileTextField(
                    controller: _weightController,
                    label: _isEnglish ? "Weight (kg)" : "체중 (kg)",
                    hint: _isEnglish ? "Enter weight" : "체중을 입력하세요 (kg)",
                    icon: Icons.monitor_weight_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 🛠️ [명칭 전면 개정 2]: "음성브리핑 및 오디오 설정" ➡️ "알림설정" 변경 완료
            Text(_isEnglish ? "Notification Settings" : "알림설정", style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1A1A32), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(_isEnglish ? "Voice Announcements" : "실시간 음성 알림 가동", style: const TextStyle(color: Colors.white, fontSize: 15)),
                    subtitle: Text(_isEnglish ? "Enable/Disable target status sound" : "주행 안내 및 종료 격려 소리를 켜거나 끕니다.", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    value: _isSpeechEnabled,
                    activeColor: Colors.cyanAccent,
                    onChanged: (bool value) => setState(() => _isSpeechEnabled = value),
                  ),
                  
                  if (_isSpeechEnabled) ...[
                    const Divider(color: Colors.white12, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_isEnglish ? "Voice Volume" : "음성 브리핑 소리 크기", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              Text("${(_speechVolume * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.volume_down_rounded, color: Colors.white30, size: 20),
                              Expanded(
                                child: Slider(
                                  value: _speechVolume,
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 10,
                                  activeColor: Colors.cyanAccent,
                                  inactiveColor: Colors.white12,
                                  onChanged: (double value) => setState(() => _speechVolume = value),
                                ),
                              ),
                              const Icon(Icons.volume_up_rounded, color: Colors.cyanAccent, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 🛠️ [명칭 전면 개정 3]: "시스템 표준언어" ➡️ "언어설정" 변경 완료
            Text(_isEnglish ? "Language Settings" : "언어설정", style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1A1A32), borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: Text(_isEnglish ? "Use English Interface" : "영문 모드 인터페이스 사용", style: const TextStyle(color: Colors.white, fontSize: 15)),
                value: _isEnglish,
                activeColor: Colors.cyanAccent,
                onChanged: (bool value) => setState(() => _isEnglish = value),
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.black),
                label: Text(_isEnglish ? "Apply Changes" : "설정 완료 및 적용", style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _saveSettings,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF121224),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}