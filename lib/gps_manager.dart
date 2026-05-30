import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

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

  // 🛠️ 안드로이드 포어그라운드 서비스 채널과 100% 동기화되는 시동 로직
  void start(bool isEnglish, Function onUpdate) async {
    isTracking = true;
    routePoints.clear();
    dist = 0.0;
    seconds = 0;
    _lastNotifiedDist = 0.0;
    speed = 0.0;
    avgSpeed = 0.0;
    calories = 0.0;
    
    _tts.speak(isEnglish ? "Start workout." : "운동을 시작합니다.");

    // 1. 매 초마다 화면의 시간 계기판을 리프레시하는 타이머
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isTracking) return;
      seconds++;
      if (seconds > 0) {
        avgSpeed = (dist / (seconds / 3600));
      }
      calories = dist * 60;
      onUpdate(); 
    });

    // 2. 안드로이드 시스템 서비스 연결 안정화를 위한 0.4초의 안전 지연 시간 확보
    await Future.delayed(const Duration(milliseconds: 400));

    // 3. 🎯 트랭글 스타일: 시스템에 명시적으로 포어그라운드 위치 추적 서비스를 요청합니다.
    try {
      _posSub = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation, // 최고 정밀도 위성 수신 모드
          distanceFilter: 2, // 2미터 이동할 때마다 강제 트리거
          intervalDuration: const Duration(seconds: 1), // 1초 간격 갱신
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: isEnglish ? "K-Path Tracking" : "K-Path 트레킹 진행 중",
            notificationText: isEnglish 
                ? "Recording your route in the background." 
                : "주머니 속에서도 경로를 중단 없이 기록하고 있습니다.",
            notificationIcon: const AndroidResource(name: 'launcher_icon'),
            enableWakeLock: true, // 🔒 화면이 잠겨도 하드웨어 GPS 센서가 꺼지지 않도록 방어
          ),
        ),
      ).listen((Position pos) {
        if (!isTracking) return;

        // 야외에서 첫 위성 신호를 잡을 때 오차가 클 수 있으므로 45미터까지 여유롭게 필터링을 완화합니다.
        if (pos.accuracy > 45) return;

        LatLng newPoint = LatLng(pos.latitude, pos.longitude);
        
        if (routePoints.isNotEmpty) {
          double delta = Geolocator.distanceBetween(
            routePoints.last.latitude, routePoints.last.longitude,
            pos.latitude, pos.longitude
          ) / 1000; // km 단위 환산

          // 제자리에서 좌표가 미세하게 튀거나 순간이동하는 비정상 오차 차단
          if (delta < 0.05 && delta > 0.00001) {
            dist += delta;
          }
        }
        
        // 🎒 백그라운드 주머니 모드에서도 메모리에 좌표 누적 기록 (트랭글 핵심 로직)
        routePoints.add(newPoint);
        speed = pos.speed < 0 ? 0.0 : pos.speed * 3.6; // km/h 단위 정렬

        // 🛠️ 좌표 수집 즉시 콜백을 실행하여 화면 계기판과 지도의 실시간 선을 강제로 갱신합니다.
        onUpdate();

        // 🔊 500미터 구간별 정기 음성 안내
        if (dist - _lastNotifiedDist >= 0.5) {
          _speakProgress(isEnglish);
          _lastNotifiedDist = dist;
        }
      }, onError: (error) {
        debugPrint("🚨 안드로이드 위치 서비스 채널 장애 방어: $error");
      });
    } catch (e) {
      debugPrint("🚨 서비스 엔진 구동 예외 처리: $e");
    }
  }

  void _speakProgress(bool isEnglish) async {
    final prefs = await SharedPreferences.getInstance();
    bool useVoice = prefs.getBool('voice_notify') ?? true;
    if (useVoice) {
      String msg = isEnglish 
        ? "Current distance is ${dist.toStringAsFixed(1)} kilometers. Speed is ${avgSpeed.toStringAsFixed(1)} kilometers per hour." 
        : "현재 주행 거리는 ${dist.toStringAsFixed(1)} 킬로미터이며, 평균 속도는 시속 ${avgSpeed.toStringAsFixed(1)} 킬로미터입니다.";
      _tts.speak(msg);
    }
  }

  void stop() {
    isTracking = false;
    _timer?.cancel();
    _posSub?.cancel();
    _timer = null;
    _posSub = null;
  }
}