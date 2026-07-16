import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';

class GpsManager {
  static final GpsManager _instance = GpsManager._internal();
  factory GpsManager() => _instance;
  GpsManager._internal();

  final List<LatLng> routePoints = [];
  double dist = 0.0;
  int seconds = 0;
  double speed = 0.0;
  double avgSpeed = 0.0;
  int calories = 0;

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _timer;
  final FlutterTts _tts = FlutterTts();

  bool _isEnglish = false;
  double _lastSpokenDistance = 0.0;

  Future<void> initTts(bool isEnglish) async {
    _isEnglish = isEnglish;
    try {
      await _tts.setLanguage(isEnglish ? "en-US" : "ko-KR");
      await _tts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("GpsManager TTS 초기화 방어: $e");
    }
  }

  void start(bool isEnglish, VoidCallback onUpdate) {
    _isEnglish = isEnglish;
    
    stop();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds++;
      _calculateCalories();
      onUpdate();
    });

    late final LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, 
        intervalDuration: const Duration(seconds: 1), 
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: _isEnglish ? "K-Path Active" : "K-Path 백그라운드 추적 중",
          notificationText: _isEnglish 
              ? "Tracking your route perfectly..." 
              : "스마트폰이 주머니에 있어도 단 한 걸음도 놓치지 않고 끈질기게 추적합니다.",
          // 🎯 [★아이콘 매핑 수리]: 누락 우려가 있는 커스텀 흰색 아이콘 대신, 
          // 안드로이드 시스템이 100% 보장하는 메인 실행 아이콘('app_icon')으로 호출 주소를 안전하게 변경했습니다.
          notificationIcon: const AndroidResource(name: 'app_icon', defType: 'mipmap'),
          enableWakeLock: true, 
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      );
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings
    ).listen((Position position) {
      if (position.accuracy > 30.0) return;

      LatLng newPoint = LatLng(position.latitude, position.longitude);

      if (routePoints.isNotEmpty) {
        double gap = Geolocator.distanceBetween(
          routePoints.last.latitude,
          routePoints.last.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );

        if (gap > 30.0) return;

        if (gap > 1.5) { 
          dist += gap / 1000.0; 
          routePoints.add(newPoint);
        }
      } else {
        routePoints.add(newPoint);
      }

      speed = position.speed * 3.6; 
      if (speed < 0.5) speed = 0.0; 

      if (seconds > 0) {
        avgSpeed = (dist / (seconds / 3600.0));
      }

      _checkVoiceGuidance();
      onUpdate();
    }, onError: (error) {
      debugPrint("GPS 스트림 엔진 수신 예외 방어: $error");
    });
  }

  void stop() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _timer?.cancel();
    _timer = null;
  }

  void clearData() {
    routePoints.clear();
    dist = 0.0;
    seconds = 0;
    speed = 0.0;
    avgSpeed = 0.0;
    calories = 0;
    _lastSpokenDistance = 0.0;
  }

  void _calculateCalories() {
    calories = ((seconds / 60.0) * 5.2).toInt();
  }

  void _checkVoiceGuidance() {
    if (dist >= _lastSpokenDistance + 1.0) {
      _lastSpokenDistance = (dist ~/ 1.0).toDouble();
      _speakDistance();
    }
  }

  Future<void> _speakDistance() async {
    int km = _lastSpokenDistance.toInt();
    String message = _isEnglish 
        ? "You have traveled $km kilometers." 
        : "현재 누적 거리는 $km 킬로미터입니다.";
    try {
      await _tts.speak(message);
    } catch (e) {
      debugPrint("GpsManager TTS 발화 실패 방어: $e");
    }
  }
}