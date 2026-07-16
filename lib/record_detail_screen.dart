import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

class RecordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  // [★컴파일 에러 완치 핵심부]: history_screen에서 전달하는 한/영 설정 변수를 정상적으로 받아내는 수혈관 구축
  final bool isEnglish;

  const RecordDetailScreen({
    super.key, 
    required this.record,
    required this.isEnglish, // 👈 생성자에 필수 매개변수 추가 결합
  });

  // 🏁 [출발점(파란색 깃발) / 도착점(빨간색 깃발) 정밀 마커 생성 빌더]
  List<Marker> _buildRouteMarkers(List<LatLng> points) {
    List<Marker> markers = [];
    
    if (points.isEmpty) return markers;

    // 1. 🏳️‍🌈 출발지점 마커 (배열의 가장 첫 번째 좌표 - 파란색 깃발)
    markers.add(
      Marker(
        point: points.first,
        width: 60, height: 60,
        child: Column(
          children: [
            // 🎯 요청 사항 반영: 파란색 깃발(Icons.flag_rounded) 아이콘 배치
            const Icon(Icons.flag_rounded, color: Colors.blueAccent, size: 36),
            Card(
              color: Colors.black87,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                // 언어 설정 상태에 따라 '출발' / 'Start' 가변 노출 구현
                child: Text(
                  isEnglish ? 'Start' : '출발', 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            )
          ],
        ),
      ),
    );

    // 2. 🏳️‍🌈 도착지점 마커 (배열의 가장 마지막 보관 좌표 - 빨간색 깃발)
    markers.add(
      Marker(
        point: points.last,
        width: 60, height: 60,
        child: Column(
          children: [
            // 🎯 요청 사항 반영: 빨간색 깃발(Icons.flag_rounded) 아이콘 배치
            const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 36),
            Card(
              color: Colors.black87,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                // 언어 설정 상태에 따라 '도착' / 'End' 가변 노출 구현
                child: Text(
                  isEnglish ? 'End' : '도착', 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            )
          ],
        ),
      ),
    );

    return markers;
  }

  String _formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> _shareGpxFile(BuildContext context) async {
    try {
      final String? gpxString = record['gpx_string'];
      if (gpxString == null || gpxString.isEmpty) return;

      final directory = Directory('/storage/emulated/0/Download/k-path');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/shared_workout.gpx');
      await file.writeAsString(gpxString);

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'K-Path GPX File Export', 
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null
      );
    } catch (e) {
      debugPrint("GPX 공유 처리 중 예외 방어: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<LatLng> points = [];
    if (record['points'] != null) {
      final List<dynamic> pts = record['points'];
      points = pts.map((e) => LatLng(e['lat'], e['lng'])).toList();
    }

    LatLng initialCenter = const LatLng(37.5665, 126.9780);
    if (points.isNotEmpty) {
      initialCenter = points.first;
    }

    // 영어 설정일 경우 어울리는 기본 타이틀 분기 처리
    String title = record['mode'] ?? (isEnglish ? "Workout Detail" : "운동 기록 상세");
    String rawDate = record['date'] ?? "";
    String displayDate = "";
    if (rawDate.isNotEmpty) {
      try {
        DateTime parsed = DateTime.parse(rawDate);
        displayDate = "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        displayDate = rawDate;
      }
    }

    double distance = record['distance'] ?? 0.0;
    int duration = record['duration'] ?? 0;
    double avgSpeed = record['avgSpeed'] ?? 0.0;
    double calories = (record['calories'] is int) ? (record['calories'] as int).toDouble() : (record['calories'] ?? 0.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: Text(
          isEnglish ? 'Workout Detail' : '운동 기록 상세', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: Colors.cyanAccent),
            onPressed: () => _shareGpxFile(context),
          )
        ],
      ),
      body: Column(
        children: [
          // 🗺️ 상단 지도 영역
          Expanded(
            flex: 6,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.kpath',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 6.0,
                      color: Colors.red.shade700, // 시인성이 강력한 빨간색 경로선 적용 유지
                    ),
                  ],
                ),
                MarkerLayer(markers: _buildRouteMarkers(points)), // 가변 언어 지원 깃발형 출발/도착 마커 레이어
              ],
            ),
          ),

          // 📊 하단 운동 데이터 분석 패널 영역
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF16162A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          displayDate,
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.1, 
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _buildStatCard(isEnglish ? 'Distance' : '누적 거리', "${distance.toStringAsFixed(2)} km"),
                        _buildStatCard(isEnglish ? 'Duration' : '운동 시간', _formatDuration(duration)),
                        _buildStatCard(isEnglish ? 'Avg Speed' : '평균 속도', "${avgSpeed.toStringAsFixed(1)} km/h"),
                        _buildStatCard(isEnglish ? 'Calories' : '소모 열량', "${calories.toInt()} kcal"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown, 
            child: Text(
              value,
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}