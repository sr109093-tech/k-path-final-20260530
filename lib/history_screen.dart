import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'record_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final bool isEnglish;

  const HistoryScreen({super.key, required this.isEnglish});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _historyRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoryRecords();
  }

  Future<void> _loadHistoryRecords() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    List<String> historyList = prefs.getStringList('workout_history') ?? [];
    List<Map<String, dynamic>> tempRecords = [];

    for (String recordStr in historyList) {
      try {
        Map<String, dynamic> record = jsonDecode(recordStr);
        tempRecords.add(record);
      } catch (e) {
        debugPrint("기록 파싱 실패 데이터 스킵: $e");
      }
    }

    setState(() {
      _historyRecords = tempRecords;
      _isLoading = false;
    });
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // 🛠️ [중요]: 꼬인 구형 0점짜리 이물질 데이터를 스마트폰 장부에서 깨끗이 청소하는 방어벽
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(widget.isEnglish ? "Clear History" : "전체 기록 삭제", style: const TextStyle(color: Colors.white)),
        content: Text(widget.isEnglish ? "Do you want to delete all old records?" : "장부에 꼬여있는 과거 모든 불량 데이터를 싹 비우시겠습니까?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(child: Text(widget.isEnglish ? "Cancel" : "취소"), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(widget.isEnglish ? "Delete" : "삭제"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await prefs.remove('workout_history');
      _loadHistoryRecords();
    }
  }

  String _formatDate(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121224),
      appBar: AppBar(
        title: Text(widget.isEnglish ? "Workout History" : "과거 운동기록 보관소"),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 26),
            tooltip: widget.isEnglish ? "Clear All" : "전체 기록 삭제",
            onPressed: _clearAllHistory,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
            onPressed: _loadHistoryRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _historyRecords.isEmpty
              ? Center(child: Text(widget.isEnglish ? "No records found." : "저장된 주행 기록 정보가 없습니다.", style: const TextStyle(color: Colors.white54, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyRecords.length,
                  itemBuilder: (context, index) {
                    final record = _historyRecords[index];
                    
                    // 🎯 [요청사항 복원 핵심]: 고정된 영문 WALKING 대신 장부에 이쁘게 작명된 한국어 타이틀 추출
                    String recordTitle = record['mode'] ?? (widget.isEnglish ? "Workout" : "기록 주행");
                    String recordDate = record['date'] != null ? _formatDate(record['date']) : "";
                    
                    // 서브 가이드에 매칭될 실물 배보된 GPX 파일 이름 가이드 추출
                    String safeDate = recordDate.replaceAll(RegExp(r'[-시작: ]'), '');
                    String subGpxName = "K-Path_Record_$safeDate.gpx";

                    return Card(
                      color: const Color(0xFF1A1A32),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      borderOnForeground: false,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFF121224), shape: BoxShape.circle),
                          child: const Icon(Icons.directions_run_rounded, color: Colors.cyanAccent, size: 28),
                        ),
                        title: Text(
                          recordTitle, // 🔒 "걷기 2026.06.03 방이동" 형태로 가변 반영 완료!
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(recordDate, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(subGpxName, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordDetailScreen(record: record, isEnglish: widget.isEnglish),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}