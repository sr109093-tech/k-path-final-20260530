import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert'; 
import 'dart:io'; 
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter_tts/flutter_tts.dart'; // 🔗 독립형 오디오 TTS 엔진 연동
import 'package:shared_preferences/shared_preferences.dart'; 
import 'gps_manager.dart'; 

class TrackingScreen extends StatefulWidget {
  final String mode;
  final bool isEnglish;

  const TrackingScreen({super.key, required this.mode, required this.isEnglish});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  final ImagePicker _picker = ImagePicker();
  final GpsManager _gpsManager = GpsManager(); 
  final FlutterTts _localTts = FlutterTts(); // 안전 구동을 위한 자체 TTS 객체
  
  bool _isTracking = false;
  Position? _currentPosition;
  bool _isSatelliteMode = false;
  Timer? _uiTimer; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gpsManager.initTts(widget.isEnglish); 
      _initLocalTts(); 
      _initCurrentLocation();
    });
  }

  Future<void> _initLocalTts() async {
    try {
      await _localTts.setLanguage(widget.isEnglish ? "en-US" : "ko-KR");
      await _localTts.setSpeechRate(0.5); 
    } catch (e) {
      debugPrint("로컬 TTS 초기화 실패 방어: $e");
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> _initCurrentLocation() async {
    bool hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) return;
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() => _currentPosition = position);
        _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
      }
    } catch (e) {
      debugPrint("초기 위치 오류: $e");
    }
  }

  void _toggleTracking() async {
    if (_isTracking) {
      _showExitConfirmation();
    } else {
      bool hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) return;
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _isTracking = true;
          _currentPosition = position;
        });

        _gpsManager.start(widget.isEnglish, () {
          if (mounted) {
            setState(() {
              if (_gpsManager.routePoints.isNotEmpty) {
                _currentPosition = Position(
                  latitude: _gpsManager.routePoints.last.latitude,
                  longitude: _gpsManager.routePoints.last.longitude,
                  timestamp: DateTime.now(),
                  accuracy: 0.0, altitude: 0.0, altitudeAccuracy: 0.0, heading: 0.0, headingAccuracy: 0.0,
                  speed: _gpsManager.speed / 3.6, speedAccuracy: 0.0,
                );
              }
            });
          }
        });

        _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isTracking) setState(() {});
        });
        _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
      } catch (e) {
        debugPrint("트래킹 시작 지점 오류: $e");
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(widget.isEnglish ? 'Pause Tracking' : '트레킹 일시정지', style: const TextStyle(color: Colors.white)),
          content: Text(widget.isEnglish ? 'Do you want to save and exit?' : '운동을 완전히 종료하고 저장하시겠습니까?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(child: Text(widget.isEnglish ? 'Resume' : '이어쓰기', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: Text(widget.isEnglish ? 'Save & Exit' : '저장 후 종료'), onPressed: () { Navigator.of(context).pop(); _saveAndStopTracking(); }),
          ],
        );
      },
    );
  }

  String _convertToGpx(List<LatLng> points, String customTitle) {
    String currentTime = DateTime.now().toUtc().toIso8601String();
    StringBuffer gpx = StringBuffer();
    gpx.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    gpx.writeln('<gpx version="1.1" creator="K-Path" xmlns="http://www.topografix.com/GPX/1/1">');
    gpx.writeln('  <metadata><time>$currentTime</time></metadata>');
    gpx.writeln('  <trk><name>$customTitle</name><type>${widget.mode}</type><trkseg>');
    for (var pt in points) {
      gpx.writeln('      <trkpt lat="${pt.latitude}" lon="${pt.longitude}"></trkpt>');
    }
    gpx.writeln('    </trkseg></trk></gpx>');
    return gpx.toString();
  }

  Future<String> _getPlaceName() async {
    if (_gpsManager.routePoints.isEmpty) return widget.isEnglish ? "Route" : "주행지역";
    try {
      await setLocaleIdentifier("ko_KR"); 
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _gpsManager.routePoints.last.latitude,
        _gpsManager.routePoints.last.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String locationName = (place.subLocality != null && place.subLocality!.isNotEmpty) 
            ? place.subLocality! 
            : (place.locality ?? "");
        return locationName.isEmpty ? (widget.isEnglish ? "Park" : "공원부근") : locationName;
      }
    } catch (e) {
      debugPrint("주소명 변환 실패: $e");
    }
    return widget.isEnglish ? "Park" : "공원부근";
  }

  Future<void> _saveAndStopTracking() async {
    setState(() => _isTracking = false);
    _uiTimer?.cancel();
    
    // 🎯 운동 종료 시 독립형 오디오 TTS 멘트 직접 재생
    try {
      String closingSpeech = widget.isEnglish 
          ? "Workout finished. Excellent job today!" 
          : "운동을 종료합니다. 수고하셨습니다.";
          
      await _localTts.speak(closingSpeech);
    } catch (e) {
      debugPrint("종료 로컬 TTS 가동 실패 방어: $e");
    }

    try {
      String koreanMode = widget.mode;
      if (widget.mode == "Walking") koreanMode = "걷기";
      else if (widget.mode == "Running") koreanMode = "달리기";
      else if (widget.mode == "Cycling") koreanMode = "자전거";
      else if (widget.mode == "Hiking") koreanMode = "등산";

      DateTime now = DateTime.now();
      String dateString = "${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}";
      
      String placeName = await _getPlaceName();
      String customTitle = "$koreanMode $dateString $placeName";

      String gpxData = _convertToGpx(_gpsManager.routePoints, customTitle);
      final String downloadPath = '/storage/emulated/0/Download';
      final Directory kpathDir = Directory('$downloadPath/k-path');
      if (!await kpathDir.exists()) await kpathDir.create(recursive: true);

      String timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
      File gpxFile = File('${kpathDir.path}/K-Path_${widget.mode}_$timestamp.gpx');
      await gpxFile.writeAsString(gpxData);

      final prefs = await SharedPreferences.getInstance();
      List<String> historyList = prefs.getStringList('workout_history') ?? [];
      List<Map<String, double>> pointsJson = _gpsManager.routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();

      Map<String, dynamic> newRecord = {
        'date': DateTime.now().toIso8601String(), 
        'mode': customTitle, 
        'distance': _gpsManager.dist,
        'duration': _gpsManager.seconds, 
        'calories': _gpsManager.calories, 
        'avgSpeed': _gpsManager.avgSpeed,
        'points': pointsJson, 
        'gpx_string': gpxData,
      };
      historyList.insert(0, jsonEncode(newRecord));
      await prefs.setStringList('workout_history', historyList);
    } catch (e) {
      debugPrint("실물 파일 백업 기록 시스템 예외: $e");
    }
    _gpsManager.stop();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _takeLivePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish ? "Photo captured successfully!" : "현장 사진이 정상적으로 촬영되었습니다!"),
            backgroundColor: Colors.purple.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint("카메라 하드웨어 구동 실패: $e");
    }
  }

  String _formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    LatLng markerPoint = const LatLng(37.5665, 126.9780);
    if (_gpsManager.routePoints.isNotEmpty) markerPoint = _gpsManager.routePoints.last;
    else if (_currentPosition != null) markerPoint = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    String displayName = widget.mode;
    if (widget.mode == "Walking") displayName = widget.isEnglish ? "Walking" : "걷기";
    else if (widget.mode == "Running") displayName = widget.isEnglish ? "Running" : "달리기";
    else if (widget.mode == "Cycling") displayName = widget.isEnglish ? "Cycling" : "자전거";
    else if (widget.mode == "Hiking") displayName = widget.isEnglish ? "Hiking" : "등산";

    return Scaffold(
      appBar: AppBar(title: Text('$displayName ${widget.isEnglish ? 'Tracking' : '기록'}'), backgroundColor: const Color(0xFF1A1A2E)),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // [위젯 1] 지도가 표출되는 메인 영역
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: markerPoint, initialZoom: 16.0),
              children: [
                TileLayer(
                  urlTemplate: _isSatelliteMode
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.my_gps_app',
                ),
                PolylineLayer(polylines: [Polyline(points: _gpsManager.routePoints, strokeWidth: 5, color: Colors.cyanAccent)]),
                MarkerLayer(markers: [Marker(point: markerPoint, child: const Icon(Icons.location_on, color: Colors.red, size: 40))]),
              ],
            ),

            // [위젯 2] 상단 반투명 보라색 실시간 운동 메터 상태바
            Positioned(
              top: 10, left: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.65), 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(widget.isEnglish ? 'Dist' : '거리', "${_gpsManager.dist.toStringAsFixed(2)} km"),
                    _buildStatColumn(widget.isEnglish ? 'Time' : '시간', _formatDuration(_gpsManager.seconds)),
                    _buildStatColumn(widget.isEnglish ? 'Speed' : '속도', "${_gpsManager.speed.toStringAsFixed(1)} km/h"),
                  ],
                ),
              ),
            ),

            // [위젯 3] 우측 수직 플로팅 스위치 패널 (카메라 복원 완료)
            Positioned(
              right: 20, top: 110,
              child: Column(
                children: [
                  FloatingActionButton.small(heroTag: 'my_sat_toggle', onPressed: () => setState(() => _isSatelliteMode = !_isSatelliteMode), backgroundColor: _isSatelliteMode ? Colors.cyanAccent : Colors.white.withOpacity(0.8), child: Icon(Icons.layers, color: _isSatelliteMode ? Colors.black : Colors.black87)),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(heroTag: 'my_loc_recenter', onPressed: _initCurrentLocation, backgroundColor: Colors.white.withOpacity(0.8), child: const Icon(Icons.my_location, color: Colors.blue)),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'kpath_camera_button', 
                    onPressed: _takeLivePhoto, 
                    backgroundColor: Colors.orangeAccent, 
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 18)
                  ),
                ],
              ),
            ),

            // [위젯 4] 최하단 운동 시작 / 종료 대형 제어 액션 버턴
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  onPressed: _toggleTracking,
                  backgroundColor: _isTracking ? Colors.orange : Colors.cyanAccent,
                  label: Text(
                    _isTracking 
                        ? (widget.isEnglish ? 'Pause' : '일시정지 / 종료') 
                        : (widget.isEnglish ? 'Start' : '운동시작'), 
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                  ),
                  icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}