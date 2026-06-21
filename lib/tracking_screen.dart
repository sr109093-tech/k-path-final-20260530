import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert'; 
import 'dart:io'; 
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'gps_manager.dart'; 

class TrackingScreen extends StatefulWidget {
  final String mode;
  final bool isEnglish;
  final bool autoRecover; 

  const TrackingScreen({
    super.key, 
    required this.mode, 
    required this.isEnglish, 
    this.autoRecover = false
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  final ImagePicker _picker = ImagePicker();
  final GpsManager _gpsManager = GpsManager(); 
  final FlutterTts _localTts = FlutterTts(); 
  
  final GlobalKey _globalKey = GlobalKey();
  
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
      final prefs = await SharedPreferences.getInstance();
      double volume = prefs.getDouble('speech_volume') ?? 1.0; 

      await _localTts.setLanguage(widget.isEnglish ? "en-US" : "ko-KR");
      await _localTts.setSpeechRate(0.5); 
      await _localTts.setVolume(volume); 
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
    
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
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

  void _handleStartButtonPress() async {
    if (_isTracking) {
      _showExitConfirmation();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final bool hasCrashData = prefs.getBool('crash_is_tracking') ?? false;

      if (hasCrashData && mounted) {
        _showRecoverSelectionDialog();
      } else {
        _startFreshTracking();
      }
    }
  }

  void _showRecoverSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(widget.isEnglish ? "Resume Option" : "이전 기록 발견", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          widget.isEnglish 
              ? "An incomplete workout record was found. Would you like to resume writing or start a fresh one?" 
              : "비정상적으로 종료된 이전 운동 데이터가 존재합니다.\n이어서 계속 작성하시겠습니까, 아니면 새로 시작하시겠습니까?", 
          style: const TextStyle(color: Colors.white70, fontSize: 14)
        ),
        actions: [
          TextButton(
            child: Text(widget.isEnglish ? "Start Fresh" : "새로 시작", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('crash_is_tracking', false); 
              _startFreshTracking(); 
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            child: Text(widget.isEnglish ? "Resume" : "이어쓰기", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context);
              _recoverPreviousTrackingSession(); 
            },
          ),
        ],
      ),
    );
  }

  void _startFreshTracking() async {
    bool hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) return;
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _isTracking = true;
        _currentPosition = position;
      });

      _startGpsTrackingEngine();
      _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
    } catch (e) {
      debugPrint("기본 주행 시동 실패: $e");
    }
  }

  void _recoverPreviousTrackingSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawPoints = prefs.getString('crash_points');
      if (rawPoints != null) {
        final List<dynamic> decoded = jsonDecode(rawPoints);
        final List<LatLng> recoveredPoints = decoded.map((e) => LatLng(e['lat'], e['lng'])).toList();
        
        setState(() {
          _gpsManager.routePoints.clear();
          _gpsManager.routePoints.addAll(recoveredPoints);
          _gpsManager.dist = prefs.getDouble('crash_dist') ?? 0.0;
          _gpsManager.seconds = prefs.getInt('crash_seconds') ?? 0;
          _isTracking = true;
        });

        _startGpsTrackingEngine();
        
        if (_gpsManager.routePoints.isNotEmpty) {
          _mapController.move(_gpsManager.routePoints.last, 16.0);
        }
      }
    } catch (e) {
      debugPrint("이어쓰기 블랙박스 디코딩 에러: $e");
    }
  }

  void _startGpsTrackingEngine() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('crash_is_tracking', true);
    await prefs.setString('crash_mode', widget.mode);

    // 🚀 [실시간 화면 매핑 동기화]: 하드웨어 센서 데이터를 받는 즉시 화면 UI를 강제로 다시 그려 멈춤을 방지합니다.
    _gpsManager.start(widget.isEnglish, () async {
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
            _mapController.move(_gpsManager.routePoints.last, _mapController.camera.zoom);
          }
        });

        final List<Map<String, double>> cacheJson = _gpsManager.routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
        await prefs.setString('crash_points', jsonEncode(cacheJson));
        await prefs.setDouble('crash_dist', _gpsManager.dist);
        await prefs.setInt('crash_seconds', _gpsManager.seconds);
      }
    });

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isTracking) setState(() {});
    });
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
    
    final prefs = await SharedPreferences.getInstance();
    final bool isSpeechEnabled = prefs.getBool('is_speech_enabled') ?? true; 

    if (isSpeechEnabled) {
      try {
        double volume = prefs.getDouble('speech_volume') ?? 1.0;
        await _localTts.setVolume(volume); 

        String closingSpeech = widget.isEnglish 
            ? "Workout finished. Excellent job today!" 
            : "운동을 종료합니다. 수고하셨습니다.";
            
        await _localTts.speak(closingSpeech);
      } catch (e) {
        debugPrint("종료 로컬 TTS 가동 실패 방어: $e");
      }
    }

    await prefs.setBool('crash_is_tracking', false);
    await prefs.remove('crash_points');
    await prefs.remove('crash_dist');
    await prefs.remove('crash_seconds');

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

  Future<void> _captureScreenAndSave() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final String downloadPath = '/storage/emulated/0/Download';
      final Directory kpathDir = Directory('$downloadPath/k-path/screenshots');
      if (!await kpathDir.exists()) await kpathDir.create(recursive: true);

      DateTime now = DateTime.now();
      String timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
      File imgFile = File('${kpathDir.path}/KPath_Capture_$timestamp.png');
      await imgFile.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish ? "Map Screen captured & saved successfully!" : "지도 화면이 성공적으로 스크린 캡처되어 저장되었습니다!"),
            backgroundColor: Colors.teal.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint("정밀 스크린샷 캡처 엔진 충돌 방어: $e");
    }
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
      appBar: AppBar(
        title: Text('$displayName ${widget.isEnglish ? 'Tracking' : '기록'}'), 
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.screenshot_monitor_rounded, color: Colors.cyanAccent), 
            tooltip: widget.isEnglish ? 'Screen Capture' : '화면 스크린 캡처',
            onPressed: _captureScreenAndSave, 
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: SizedBox.expand(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: markerPoint, 
                  initialZoom: 16.0
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isSatelliteMode
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', 
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.kpath',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _gpsManager.routePoints, 
                        strokeWidth: 6, 
                        color: Colors.blue.shade700
                      )
                    ]
                  ),
                  MarkerLayer(markers: [Marker(point: markerPoint, child: const Icon(Icons.location_on, color: Colors.red, size: 42))]),
                ],
              ),

              Positioned(
                top: 10, left: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A32).withOpacity(0.9), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1),
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

              Positioned(
                right: 20, top: 110,
                child: Column(
                  children: [
                    FloatingActionButton.small(heroTag: 'my_sat_toggle', onPressed: () => setState(() => _isSatelliteMode = !_isSatelliteMode), backgroundColor: _isSatelliteMode ? Colors.cyanAccent : Colors.white.withOpacity(0.9), child: Icon(Icons.layers, color: _isSatelliteMode ? Colors.black : Colors.black87)),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(heroTag: 'my_loc_recenter', onPressed: _initCurrentLocation, backgroundColor: Colors.white.withOpacity(0.9), child: const Icon(Icons.my_location, color: Colors.blue)),
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

              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Center(
                  child: FloatingActionButton.extended(
                    onPressed: _handleStartButtonPress, 
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
