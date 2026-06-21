import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsManager {
  static final GpsManager _instance = GpsManager._internal();
  factory GpsManager() => _instance;
  GpsManager._internal();

  final FlutterTts flutterTts = FlutterTts();
  StreamSubscription<Position>? _positionStreamSubscription;

  final List<LatLng> routePoints = [];
  double dist = 0.0;
  int seconds = 0;
  double speed = 0.0;
  double avgSpeed = 0.0;
  double calories = 0.0;

  Timer? _timer;

  Future<void> initTts(bool isEnglish) async {
    try {
      await flutterTts.setLanguage(isEnglish ? "en-US" : "ko-KR");
      await flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("GpsManager TTS 초기화 방어: $e");
    }
  }

  Future<void> speakRouteStatus(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isSpeechEnabled = prefs.getBool('is_speech_enabled') ?? true;
      
      if (!isSpeechEnabled) return;

      await flutterTts.speak(message);
    } catch (e) {
      debugPrint("GpsManager 음성 방송 실패 방어: $e");
    }
  }

  // 🔒 [실시간 & 백그라운드 동시 인양 시동 기어]
  void start(bool isEnglish, VoidCallback onUpdate) {
    routePoints.clear();
    dist = 0.0;
    seconds = 0;
    speed = 0.0;
    avgSpeed = 0.0;
    calories = 0.0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds++;
      _calculateCalories();
      onUpdate(); 
    });

    // 🎯 [실시간 지연 원천 박멸]: 시스템 절전 Doze 모드를 완전히 깨부수기 위해 
    // AndroidSettings 포그라운드 노티피케이션 옵션을 명확하게 활성화 결속합니다.
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation, // 네비게이션급 최상위 위성 정밀도 가동
      distanceFilter: 0, // 미세한 요동이나 1cm의 발걸음도 단 하나도 누락 없이 즉시 수집
      forceLocationManager: true, // 구글 플레이 서비스 의존성을 우회하여 GPS 순수 하드웨어를 강제 구동
      intervalDuration: const Duration(seconds: 1), // 1초 간격 실시간 무중단 동기화
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "K-Path가 주행 경로를 끊김 없이 실시간 기록 중입니다.",
        notificationTitle: "실시간 경로 추적 활성화",
        enableWakeLock: true, // 화면이 꺼져도 CPU 프로세서가 잠들지 않도록 제어
      ),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings
    ).listen((Position position) async {
      
      LatLng newPoint = LatLng(position.latitude, position.longitude);
      speed = position.speed * 3.6; 

      if (routePoints.isNotEmpty) {
        double distanceInMeters = Geolocator.distanceBetween(
          routePoints.last.latitude,
          routePoints.last.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );

        // 1km 주기 안내 음성 브리핑 무음 연동 레이어 완벽 보존
        final int oldDistInt = dist.toInt();
        final int newDistInt = ((dist + (distanceInMeters / 1000.0))).toInt();
        
        if (newDistInt > oldDistInt) {
          final prefs = await SharedPreferences.getInstance();
          final bool isSpeechEnabled = prefs.getBool('is_speech_enabled') ?? true;
          
          if (isSpeechEnabled) {
            double currentVolume = prefs.getDouble('speech_volume') ?? 1.0;
            await flutterTts.setVolume(currentVolume);
            
            String kmSpeech = isEnglish 
                ? "You have walked $newDistInt kilometers." 
                : "현재 $newDistInt 킬로미터 주행 중입니다.";
            await flutterTts.speak(kmSpeech);
          }
        }

        dist += distanceInMeters / 1000.0; 
      }

      routePoints.add(newPoint);
      avgSpeed = seconds > 0 ? (dist / (seconds / 3600.0)) : 0.0;
      onUpdate(); 
    });
  }

  void stop() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _timer = null;
    _positionStreamSubscription = null;
  }

  void _calculateCalories() {
    calories += 0.05;
  }
}