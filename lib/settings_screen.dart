import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 

// 스크린샷(2)를 확인하니 파일들이 lib 폴더에 바로 있네요. 
// 같은 폴더 내에 있으므로 파일명만 적으면 연결됩니다.
import 'user_settings_screen.dart';
import 'language_settings_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Container(
        color: const Color(0xFF16213E),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            // 1. 기존 메뉴: 사용자 등록
            _buildSettingItem(
              context,
              icon: Icons.person_outline,
              title: '사용자 등록',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSettingsScreen()),
              ),
            ),

            // 2. 기존 메뉴: 언어 설정
            _buildSettingItem(
              context,
              icon: Icons.language,
              title: '언어 설정',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
              ),
            ),

            // 3. 기존 메뉴: 알림 설정
            _buildSettingItem(
              context,
              icon: Icons.notifications_none,
              title: '알림 설정',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(color: Colors.white24, height: 40),
            ),

            // 4. 새 메뉴: 휴대폰 시스템의 [앱 정보] 화면으로 연결
            _buildSettingItem(
              context,
              icon: Icons.settings_applications,
              title: '시스템 앱 설정',
              subtitle: '권한, 알림, 배터리 제한 등 상세 관리',
              iconColor: Colors.cyanAccent, 
              onTap: () async {
                // 이 한 줄이 휴대폰 본래의 설정창을 띄워줍니다.
                await Geolocator.openAppSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 메뉴 디자인을 담당하는 위젯
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color iconColor = Colors.white70,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white24,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}