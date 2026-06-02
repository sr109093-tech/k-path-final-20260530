import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class RecordDetailScreen extends StatefulWidget {
  final Map<String, dynamic> record;
  final bool isEnglish;

  const RecordDetailScreen({super.key, required this.record, required this.isEnglish});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  final MapController _mapController = MapController();
  bool _isSatelliteMode = false;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _parseRoutePoints();
  }

  void _parseRoutePoints() {
    try {
      if (widget.record['points'] != null) {
        final List<dynamic> pts = widget.record['points'];
        final List<LatLng> tempPoints = [];
        for (var p in pts) {
          if (p != null && p['lat'] != null && p['lng'] != null) {
            tempPoints.add(LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()));
          }
        }
        setState(() => _routePoints = tempPoints);
      }
    } catch (e) {
      debugPrint("🚨 좌표 파싱 에러 방어: $e");
    }
  }

  Future<void> _exportGpxFile() async {
    final String? gpxString = widget.record['gpx_string'];
    if (gpxString == null || gpxString.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isEnglish ? 'No GPX data available.' : 'GPX 데이터 파일이 존재하지 않습니다.')));
      }
      return;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final String safeDate = widget.record['date'].toString().replaceAll(RegExp(r'[:.]'), '-');
      final file = await File('${tempDir.path}/K-Path_Export_$safeDate.gpx').create();
      await file.writeAsString(gpxString);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles([XFile(file.path)], text: 'K-Path GPX File Export', sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPX 내보내기 실패: $e')));
    }
  }

  String _formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
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
    LatLng centerPoint = const LatLng(37.5665, 126.9780);
    if (_routePoints.isNotEmpty) centerPoint = _routePoints.first;

    // 🛠️ [★해결 핵심 2]: 캐시 저장 타입 불일치 버그 전면 치료 (int/double 매핑 정렬)
    double distance = 0.0;
    if (widget.record['distance'] != null) {
      distance = (widget.record['distance'] as num).toDouble();
    }

    int duration = 0;
    if (widget.record['duration'] != null) {
      duration = (widget.record['duration'] as num).toInt();
    }

    double avgSpeed = 0.0;
    if (widget.record['avgSpeed'] != null) {
      avgSpeed = (widget.record['avgSpeed'] as num).toDouble();
    }

    double calories = 0.0;
    if (widget.record['calories'] != null) {
      calories = (widget.record['calories'] as num).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Workout Detail' : '운동 기록 상세'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share, color: Colors.cyanAccent), onPressed: _exportGpxFile),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: centerPoint, initialZoom: 15.0),
                  children: [
                    TileLayer(
                      urlTemplate: _isSatelliteMode
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.my_gps_app',
                    ),
                    if (_routePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _routePoints, strokeWidth: 5, color: Colors.cyanAccent)]),
                  ],
                ),
                Positioned(
                  right: 15,
                  top: 15,
                  child: FloatingActionButton.small(
                    heroTag: 'dt_map_sat',
                    onPressed: () => setState(() => _isSatelliteMode = !_isSatelliteMode),
                    backgroundColor: _isSatelliteMode ? Colors.cyanAccent : Colors.white.withOpacity(0.8),
                    child: Icon(Icons.layers, color: _isSatelliteMode ? Colors.black : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(color: Color(0xFF121224)),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🔒 한글 커스텀 명칭이 그대로 다이렉트 표출됩니다.
                        Expanded(
                          child: Text(
                            widget.record['mode'] ?? 'Workout', 
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(_formatDate(widget.record['date'] ?? ''), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.8, 
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 12,
                      children: [
                        _buildStatBox(widget.isEnglish ? 'Distance' : '누적 거리', "${distance.toStringAsFixed(2)} km"),
                        _buildStatBox(widget.isEnglish ? 'Duration' : '운동 시간', _formatDuration(duration)),
                        _buildStatBox(widget.isEnglish ? 'Avg Speed' : '평균 속도', "${avgSpeed.toStringAsFixed(1)} km/h"),
                        _buildStatBox(widget.isEnglish ? 'Calories' : '소모 열량', "${calories.toStringAsFixed(0)} kcal"),
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

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF1A1A30), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}