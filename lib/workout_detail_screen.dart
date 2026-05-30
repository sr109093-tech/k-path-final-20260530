import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  const WorkoutDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    // 🛡️ 안전한 경로 파싱 (인구님이 겪으신 에러의 핵심 해결책)
    List<dynamic> rawPoints = record['points'] ?? [];
    List<LatLng> points = rawPoints.map((p) {
      try {
        if (p is Map) {
          // 키(lat, lng)로 저장된 경우
          return LatLng(
            double.parse(p['lat'].toString()),
            double.parse(p['lng'].toString()),
          );
        } else if (p is List && p.length >= 2) {
          // 리스트([0], [1])로 저장된 경우 (에러 발생 지점 방어)
          return LatLng(
            double.parse(p[0].toString()),
            double.parse(p[1].toString()),
          );
        }
      } catch (e) {
        debugPrint("좌표 파싱 오류: $e");
      }
      return const LatLng(0, 0);
    }).where((p) => p.latitude != 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(record['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat("총 거리", "${record['distance']} km"),
                _stat("운동 시간", record['time']),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: points.isNotEmpty ? points.last : const LatLng(37.56, 126.97),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png",
                  userAgentPackageName: 'com.example.my_gps_app',
                ),
                PolylineLayer(polylines: [
                  Polyline(
                    points: points,
                    color: Colors.red,
                    strokeWidth: 5,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ]),
                if (points.isNotEmpty)
                  MarkerLayer(markers: [
                    Marker(
                      point: points.last,
                      width: 45,
                      height: 45,
                      child: const Icon(Icons.flag, color: Colors.blue, size: 40),
                    ),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String l, String v) => Column(
    children: [
      Text(l, style: const TextStyle(color: Colors.black54, fontSize: 14)),
      const SizedBox(height: 5),
      Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
    ],
  );
}