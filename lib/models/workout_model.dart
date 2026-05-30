import 'dart:convert';
import 'package:latlong2/latlong.dart';

class WorkoutRecord {
  final String date;
  final String distance;
  final String time;
  final List<LatLng> points;

  WorkoutRecord({
    required this.date,
    required this.distance,
    required this.time,
    required this.points,
  });

  // 데이터를 글자(JSON)로 바꿔서 저장할 때 사용
  String toJson() {
    List<Map<String, double>> polyPoints = points
        .map((p) => {"lat": p.latitude, "lng": p.longitude})
        .toList();
    return jsonEncode({
      "date": date,
      "distance": distance,
      "time": time,
      "points": polyPoints,
    });
  }
}