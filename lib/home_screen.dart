import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'translations.dart';
import 'tracking_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double totalDist = 0.0;
  int workoutCount = 0;
  String? _profileImage;
  String _currentUserId = 'guest';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    AppText.lang = prefs.getString('lang') ?? 'ko';
    _currentUserId = prefs.getString('user_id') ?? 'guest';
    
    List<String> history = prefs.getStringList('workouts_$_currentUserId') ?? [];
    double distSum = 0.0;
    for (var item in history) {
      try {
        final data = jsonDecode(item);
        distSum += double.tryParse(data['distance'].toString()) ?? 0.0;
      } catch (e) { continue; }
    }

    if (mounted) {
      setState(() {
        totalDist = distSum;
        workoutCount = history.length;
        _profileImage = prefs.getString('user_image');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double topSpace = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: Row(children: [
                _buildQuadrant(context, AppText.get('walk'), Icons.directions_walk, const Color(0xFFE54D42)),
                _buildQuadrant(context, AppText.get('hike'), Icons.terrain, const Color(0xFFF39C12)),
              ])),
              Expanded(child: Row(children: [
                _buildQuadrant(context, AppText.get('bike'), Icons.directions_bike, const Color(0xFF9B59B6)),
                _buildQuadrant(context, AppText.get('run'), Icons.directions_run, const Color(0xFF27AE60)),
              ])),
            ],
          ),

          Positioned(
            top: topSpace + 10,
            right: 15,
            child: Row(
              children: [
                if (_profileImage != null)
                  Container(
                    width: 40, height: 40,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(image: FileImage(File(_profileImage!)), fit: BoxFit.cover),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 35),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    _refreshData();
                  },
                ),
              ],
            ),
          ),

          // 🏷️ 좌측 상단: 'K-Path'만 깔끔하게 표시
          Positioned(
            top: topSpace + 15,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                  child: Text(AppText.get('app_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 5),
                Text("User: $_currentUserId", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          Center(
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                _refreshData();
              },
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 15)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${totalDist.toStringAsFixed(1)}km", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Text("$workoutCount records", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrant(BuildContext context, String label, IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(mode: label, isEnglish: AppText.lang == 'en')));
          _refreshData();
        },
        child: Container(
          color: color,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 100),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}