import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isVoiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _isVoiceEnabled = prefs.getBool('voice_notify') ?? true; });
  }

  _saveSetting(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_notify', val);
    setState(() { _isVoiceEnabled = val; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("알림 설정")),
      body: SwitchListTile(
        title: const Text("음성 안내 사용"),
        subtitle: const Text("500미터마다 현재 상태를 알려줍니다."),
        value: _isVoiceEnabled,
        onChanged: _saveSetting,
      ),
    );
  }
}