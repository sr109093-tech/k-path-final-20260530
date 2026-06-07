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

  // 🛠️ [★기능 보강 핵심 2]: 꼬인 기록만 골라내어 부분 타격 처리하는 개별 레코드 파쇄 엔진
  Future<void> _deleteOneRecord(int index) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(widget.isEnglish ? "Delete Record" : "개별 운동기록 삭제", style: const TextStyle(color: Colors.white)),
        content: Text(
          widget.isEnglish 
              ? "Do you want to delete this specific workout?" 
              : "선택하신 개별 운동 주행 기록을 장부에서 영구히 삭제하시겠습니까?", 
          style: const TextStyle(color: Colors.white70)
        ),
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
      final prefs = await SharedPreferences.getInstance();
      List<String> historyList = prefs.getStringList('workout_history') ?? [];
      
      // 인덱스를 기반으로 특정 줄 데이터만 정확하게 척출 소거
      if (index >= 0 && index < historyList.length) {
        historyList.removeAt(index);
        await prefs.setStringList('workout_history', historyList);
        _loadHistoryRecords(); // 화면 리스트 갱신
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
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
                    
                    String recordTitle = record['mode'] ?? (widget.isEnglish ? "Workout" : "기록 주행");
                    String recordDate = record['date'] != null ? _formatDate(record['date']) : "";
                    
                    String safeDate = recordDate.replaceAll(RegExp(r'[-시작: ]'), '');
                    String subGpxName = "K-Path_Record_$safeDate.gpx";

                    return Card(
                      color: const Color(0xFF1A1A32),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      borderOnForeground: false,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFF121224), shape: BoxShape.circle),
                          child: const Icon(Icons.directions_run_rounded, color: Colors.cyanAccent, size: 26),
                        ),
                        title: Text(
                          recordTitle, 
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
                        // 🛠️ [★기능 보강 핵심 2]: 리스트 개별 항목 오른쪽에 쓰레기통 버튼 정렬 이식 완결!
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                              onPressed: () => _deleteOneRecord(index), // 요소를 지명하여 파괴 유도
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                          ],
                        ),
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