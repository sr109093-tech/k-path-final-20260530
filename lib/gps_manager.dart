import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart'; 
import 'translations.dart';

class GpsManager {
  bool isTracking = false;
  List<LatLng> routePoints = [];
  double dist = 0.0;
  double speed = 0.0;
  double avgSpeed = 0.0;
  double calories = 0.0;
  int seconds = 0;
  double _lastNotifiedDist = 0.0;
  
  Timer? _timer;
  StreamSubscription<Position>? _posSub;
  final FlutterTts _tts = FlutterTts();

  void initTts(bool isEnglish) {
    _tts.setLanguage(isEnglish ? "en-US" : "ko-KR");
  }

  void start(bool isEnglish, Function onUpdate) {
    isTracking = true;
    routePoints.clear();
    dist = 0.0;
    seconds = 0;
    _lastNotifiedDist = 0.0;
    
    _tts.speak(isEnglish ? "Start workout." : "운동을 시작합니다.");

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      seconds++;
      if (seconds > 0) avgSpeed = (dist / (seconds / 3600));
      calories = dist * 65; 
      onUpdate();
    });

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) async {
      LatLng newPoint = LatLng(pos.latitude, pos.longitude);
      if (routePoints.isNotEmpty) {
        dist += Geolocator.distanceBetween(
          routePoints.last.latitude, routePoints.last.longitude,
          pos.latitude, pos.longitude) / 1000;
      }
      routePoints.add(newPoint);
      speed = pos.speed * 3.6;

      if (dist - _lastNotifiedDist >= 0.5) {
        final prefs = await SharedPreferences.getInstance();
        bool useVoice = prefs.getBool('voice_notify') ?? true;
        if (useVoice) {
          String msg = isEnglish 
            ? "Current distance is ${dist.toStringAsFixed(1)} kilometers." 
            : "현재 주행 거리는 ${dist.toStringAsFixed(1)} 킬로미터입니다.";
          _tts.speak(msg);
        }
        _lastNotifiedDist = dist;
      }
      onUpdate();
    });
  }

  void stop() {
    isTracking = false;
    _timer?.cancel();
    _posSub?.cancel();
  }

  // 📂 GPX 파일 생성 및 'Download/K-Path' 폴더 자동 저장 로직
  Future<String?> saveGpx(String mode) async {
    if (routePoints.isEmpty) return null;

    try {
      String path = "";
      
      if (Platform.isAndroid) {
        // 안드로이드 공용 다운로드 폴더
        path = '/storage/emulated/0/Download/K-Path';
      } else {
        // iOS 등 기타 플랫폼
        final directory = await getApplicationDocumentsDirectory();
        path = "${directory.path}/K-Path";
      }

      // 1. 폴더 생성 확인
      final folder = Directory(path);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // 2. 파일명 생성 (년월일_시분.gpx)
      final now = DateTime.now();
      String timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_"
                         "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
      final file = File('$path/track_$timestamp.gpx');

      // 3. GPX XML 데이터 구성
      String gpxContent = '<?xml version="1.0" encoding="UTF-8"?>\n'
          '<gpx version="1.1" creator="K-Path" xmlns="http://www.topografix.com/GPX/1/1">\n'
          '  <metadata><name>$mode Record</name><time>${now.toIso8601String()}</time></metadata>\n'
          '  <trk><name>$mode</name><trkseg>\n';

      for (var point in routePoints) {
        gpxContent += '    <trkpt lat="${point.latitude}" lon="${point.longitude}"></trkpt>\n';
      }

      gpxContent += '  </trkseg></trk>\n</gpx>';

      // 4. 파일 저장
      await file.writeAsString(gpxContent);
      return file.path;
    } catch (e) {
      print("GPX 저장 에러: $e");
      return null;
    }
  }
}