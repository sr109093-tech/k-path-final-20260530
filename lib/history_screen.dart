import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'workout_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. 현재 사용자 아이디 확인
    String userId = prefs.getString('user_id') ?? 'guest';
    
    // 2. 해당 사용자 아이디의 전용 키로 데이터 로드
    List<String> history = prefs.getStringList('workouts_$userId') ?? [];
    
    setState(() {
      _workouts = history.map((item) => jsonDecode(item) as Map<String, dynamic>).toList().reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("운동 기록", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: _workouts.isEmpty
          ? const Center(child: Text("기록이 없습니다.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: _workouts.length,
              itemBuilder: (ctx, i) {
                final item = _workouts[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.history, color: Colors.white)),
                    title: Text(item['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${item['distance']} km / ${item['time']}"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutDetailScreen(record: item)));
                    },
                  ),
                );
              },
            ),
    );
  }
}