import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'gps_manager.dart'; // 🔗 선생님의 GPS 매니저 연동

class TrackingScreen extends StatefulWidget {
  final String mode;
  final bool isEnglish;

  const TrackingScreen({
    super.key,
    required this.mode,
    required this.isEnglish,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  final ImagePicker _picker = ImagePicker();
  final GpsManager _gpsManager = GpsManager(); // ⚙️ GPS 매니저 객체 생성
  
  bool _isTracking = false;
  Position? _currentPosition;
  bool _isSatelliteMode = false;
  Timer? _uiTimer; // 화면 숫자 갱신용 타이머

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gpsManager.initTts(widget.isEnglish); // TTS 언어 초기화
      _initCurrentLocation();
    });
  }

  // 위치 권한 체크 및 획득 함수
  Future<bool> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEnglish ? 'Please turn on Location Services.' : '위치 서비스를 켜주세요.'))
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.isEnglish ? 'Location permission denied.' : '위치 권한이 거부되었습니다.'))
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEnglish ? 'Enable location permission in smartphone settings.' : '스마트폰 설정에서 위치 권한을 허용해주세요.'))
        );
      }
      return false;
    }
    return true;
  }

  // 1. 초기 위치 획득 및 지도 중심 이동 (디폴트 설정)
  Future<void> _initCurrentLocation() async {
    bool hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
      }
    } catch (e) {
      debugPrint("초기 위치 에러: $e");
    }
  }

  // 2. 현재위치 버튼 클릭 시 강제 이동
  Future<void> _moveToCurrentLocation() async {
    bool hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      setState(() {
        _currentPosition = position;
      });
      _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEnglish ? 'Searching GPS...' : 'GPS 신호를 찾는 중입니다...'))
        );
      }
    }
  }

  // 3. 트레킹 제어 (시작 / 일시정지 다이얼로그 호출)
  void _toggleTracking() async {
    if (_isTracking) {
      _showExitConfirmation();
    } else {
      bool hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) return;

      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        
        setState(() {
          _isTracking = true;
          _currentPosition = position;
        });

        // ⚙️ GpsManager 실행 및 UI 실시간 갱신 연결 체인
        _gpsManager.start(widget.isEnglish, () {
          if (mounted) {
            setState(() {
              // 엔진에서 좌표가 업데이트될 때마다 지도를 부드럽게 동기화 이동시킵니다.
              if (_gpsManager.routePoints.isNotEmpty) {
                _currentPosition = Position(
                  latitude: _gpsManager.routePoints.last.latitude,
                  longitude: _gpsManager.routePoints.last.longitude,
                  timestamp: DateTime.now(),
                  accuracy: 0.0,
                  altitude: 0.0,
                  altitudeAccuracy: 0.0,
                  heading: 0.0,
                  headingAccuracy: 0.0,
                  speed: _gpsManager.speed / 3.6,
                  speedAccuracy: 0.0,
                );
              }
            });
          }
        });

        // 🛠️ 화면 계기판 수치 동결 현상 해결: 1초마다 강제로 스냅샷을 찍어 화면을 리프레시합니다.
        _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isTracking) {
            setState(() {});
          }
        });

        _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.isEnglish ? 'Failed to get location.' : '위치 정보를 가져오지 못했습니다.'))
          );
        }
      }
    }
  }

  // 팝업 장치 (실수 방지 이어쓰기 다이얼로그)
  void _showExitConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            widget.isEnglish ? 'Pause Tracking' : '트레킹 일시정지',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            widget.isEnglish 
                ? 'Do you want to save and exit?\nSelect [Resume] to continue.' 
                : '운동을 완전히 종료하고 저장하시겠습니까?\n계속하시려면 [이어쓰기]를 선택하세요.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: Text(
                widget.isEnglish ? 'Resume' : '이어쓰기',
                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text(widget.isEnglish ? 'Save & Exit' : '저장 후 종료'),
              onPressed: () {
                Navigator.of(context).pop();
                _stopTracking();
              },
            ),
          ],
        );
      },
    );
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });
    _uiTimer?.cancel();
    _gpsManager.stop(); // ⚙️ GPS 매니저 자원 해제
    Navigator.of(context).pop();
  }

  String _formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEnglish ? 'Photo saved' : '사진이 촬영되었습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEnglish ? 'Camera error' : '카메라 실행 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng markerPoint = const LatLng(37.5665, 126.9780);
    if (_gpsManager.routePoints.isNotEmpty) {
      markerPoint = _gpsManager.routePoints.last;
    } else if (_currentPosition != null) {
      markerPoint = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode} ${widget.isEnglish ? 'Tracking' : '기록'}'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // 1. 지도 레이어
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: markerPoint,
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatelliteMode
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.my_gps_app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _gpsManager.routePoints, 
                      strokeWidth: 5, 
                      color: Colors.cyanAccent
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: markerPoint,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),

            // 2. 상단 상태바 (실시간 값 매핑 보완)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      widget.isEnglish ? 'Dist' : '거리', 
                      "${_gpsManager.dist.toStringAsFixed(2)} km"
                    ),
                    _buildStatColumn(
                      widget.isEnglish ? 'Time' : '시간', 
                      _formatDuration(_gpsManager.seconds)
                    ),
                    _buildStatColumn(
                      widget.isEnglish ? 'Speed' : '속도', 
                      "${_gpsManager.speed.toStringAsFixed(1)} km/h"
                    ),
                  ],
                ),
              ),
            ),

            // 3. 우측 버튼들
            Positioned(
              right: 20,
              top: 100,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'map_type',
                    onPressed: () {
                      setState(() {
                        _isSatelliteMode = !_isSatelliteMode;
                      });
                    },
                    backgroundColor: _isSatelliteMode ? Colors.cyanAccent : Colors.white.withOpacity(0.8),
                    child: Icon(Icons.layers, color: _isSatelliteMode ? Colors.black : Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'camera',
                    onPressed: _openCamera,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: const Icon(Icons.camera_alt, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'my_location',
                    onPressed: _moveToCurrentLocation,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                ],
              ),
            ),

            // 4. 하단 버튼
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  onPressed: _toggleTracking,
                  backgroundColor: _isTracking ? Colors.orange : Colors.cyanAccent,
                  label: Text(
                    _isTracking 
                      ? (widget.isEnglish ? 'Pause / Stop' : '일시정지 / 종료') 
                      : (widget.isEnglish ? 'Start' : '트레킹 시작'),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }
}