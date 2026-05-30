import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:share_plus/share_plus.dart'; 
import 'models/workout_model.dart';

class RecordDetailScreen extends StatefulWidget {
  final WorkoutRecord record;
  const RecordDetailScreen({super.key, required this.record});
  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _picker = ImagePicker();
  XFile? _bgPhoto; bool _showMap = true;

  Future<void> _share() async {
    if (_bgPhoto == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사진을 먼저 골라주세요!'))); return; }
    showDialog(context: context, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    final Uint8List? image = await _screenshotController.capture();
    Navigator.pop(context);
    if (image != null) {
      final dir = await getTemporaryDirectory();
      final path = await File('${dir.path}/proof.png').create();
      await path.writeAsBytes(image);
      await Share.shareXFiles([XFile(path.path)], text: '오늘의 트레킹 인증샷! 🏆');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasData = widget.record.points.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text("인증샷 카드 만들기")),
      body: Column(children: [
        Expanded(flex: 1, child: hasData ? GoogleMap(initialCameraPosition: CameraPosition(target: widget.record.points.first, zoom: 15), polylines: {Polyline(polylineId: const PolylineId('r'), points: widget.record.points, color: Colors.red, width: 5)}) : const Center(child: Text("데이터 없음"))),
        Container(padding: const EdgeInsets.symmetric(vertical: 15), color: Colors.grey[100], child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_tool(Icons.photo_library, "사진 선택", () async { final p = await _picker.pickImage(source: ImageSource.gallery); if (p != null) setState(() => _bgPhoto = p); }), _tool(Icons.share, "인증샷 공유", _share)])),
        Expanded(flex: 2, child: Screenshot(controller: _screenshotController, child: _buildCard(hasData))),
      ]),
    );
  }

  Widget _buildCard(bool hasData) => Container(width: double.infinity, color: Colors.blueGrey[100], child: Stack(children: [
    if (_bgPhoto != null) Positioned.fill(child: Image.file(File(_bgPhoto!.path), fit: BoxFit.cover)),
    Positioned(top: 20, left: 20, child: Text(widget.record.date, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10)]))),
    if (_showMap && hasData) Positioned(top: 20, right: 20, width: 120, height: 120, child: Container(color: Colors.white70, child: CustomPaint(painter: _Painter(widget.record.points)))),
    Positioned(bottom: 30, left: 20, right: 20, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(15)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text("거리: ${widget.record.distance}km", style: const TextStyle(color: Colors.white)), Text("시간: ${widget.record.time}", style: const TextStyle(color: Colors.white))]))),
  ]));
  Widget _tool(IconData i, String l, VoidCallback o) => InkWell(onTap: o, child: Column(children: [Icon(i, size: 30), Text(l)]));
}

class _Painter extends CustomPainter {
  final List<LatLng> pts; _Painter(this.pts);
  @override
  void paint(Canvas canvas, Size size) {
    if (pts.isEmpty) return;
    final paint = Paint()..color = Colors.blue..strokeWidth = 3..style = PaintingStyle.stroke;
    final path = Path();
    double minLat = pts[0].latitude; double maxLat = pts[0].latitude;
    double minLon = pts[0].longitude; double maxLon = pts[0].longitude;
    for (var p in pts) {
      if (p.latitude < minLat) minLat = p.latitude; if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude; if (p.longitude > maxLon) maxLon = p.longitude;
    }
    for (int i = 0; i < pts.length; i++) {
      double x = (pts[i].longitude - minLon) / (maxLon - minLon == 0 ? 1 : maxLon - minLon) * size.width;
      double y = size.height - ((pts[i].latitude - minLat) / (maxLat - minLat == 0 ? 1 : maxLat - minLat) * size.height);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}