import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔗 알림설정 장부 연동을 위한 라이브러리 결합

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

  // 🔒 [무음 보장 검문소 1]: 외부에서 종료 오디오 호출 시 알림 스위치 상태를 실시간 확인
  Future<void> speakRouteStatus(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isSpeechEnabled = prefs.getBool('is_speech_enabled') ?? true;
      
      // 알림설정 스위치가 비활성화(false) 상태라면 아무 소리도 내지 않고 즉시 함수 파쇄 차단!
      if (!isSpeechEnabled) return;

      await flutterTts.speak(message);
    } catch (e) {
      debugPrint("GpsManager 음성 방송 실패 방어: $e");
    }
  }

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

    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, 
      forceLocationManager: true, 
      intervalDuration: const Duration(seconds: 2), 
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings
    ).listen((Position position) async {
      
      if (position.accuracy > 18.0) {
        debugPrint("🚨 도심지 불량 반사 신호 탐지 및 파쇄 (오차반경: ${position.accuracy}m) - 기록 스킵");
        return; 
      }

      LatLng newPoint = LatLng(position.latitude, position.longitude);
      speed = position.speed * 3.6; 

      if (routePoints.isNotEmpty) {
        double distanceInMeters = Geolocator.distanceBetween(
          routePoints.last.latitude,
          routePoints.last.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );

        if (distanceInMeters > 25.0 && speed > 45.0) {
          debugPrint("🚨 가짜 순간이동 신호 포착 및 제거 (이동거리: ${distanceInMeters}m) - 기록 스킵");
          return;
        }

        // 🔒 [무음 보장 검문소 2]: 1km 마다 울리던 정기 오디오 음성 브리핑 연동 통제
        // 현재 누적 거리가 소수점을 넘어 정수 단위로 변경되는 구간에서 알림설정이 꺼져있는지 안전 진단
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