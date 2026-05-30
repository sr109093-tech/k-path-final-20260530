import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'models/workout_model.dart';

class HistoryDetailScreen extends StatelessWidget {
  final WorkoutRecord record;
  const HistoryDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운동 경로 확인'), actions: [IconButton(icon: const Icon(Icons.share), onPressed: () => Share.share("${record.date} 기록 공유!"))]),
      body: FlutterMap(
        options: MapOptions(initialCenter: record.points.isNotEmpty ? record.points.first : const LatLng(37.5665, 126.9780), initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // ✅ 여기도 동일하게 수정합니다.
            userAgentPackageName: 'InkooKang.MyGPSApp.v1.sr109093',
          ),
          PolylineLayer(polylines: [Polyline(points: record.points, color: Colors.redAccent, strokeWidth: 5)]),
        ],
      ),
    );
  }
}