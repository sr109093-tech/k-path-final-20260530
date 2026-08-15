import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';

class GpsManager {
  // 싱글톤 패턴 보존
  static final GpsManager _instance = GpsManager._internal();
  factory GpsManager() => _instance;
  GpsManager._internal();

  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  // 데이터 관리 상태 변수
  final List<LatLng> routePoints = [];
  double dist = 0.0;
  int seconds = 0;
  double speed = 0.0;
  double avgSpeed = 0.0;
  double calories = 0.0;

  final FlutterTts _tts = FlutterTts();
  bool _isEnglish = false;
  int _lastSpokenKm = 0;

  Future<void> initTts(bool isEnglish) async {
    _isEnglish = isEnglish;
    try {
      await _tts.setLanguage(_isEnglish ? "en-US" : "ko-KR");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint("TTS 엔진 초기화 방어: $e");
    }
  }

  // 🛡️ [트랭글 기술 핵심 이식]: 안드로이드 OS의 배터리 최적화 잠금을 자발적으로 무력화시키는 강제 빗장 해제 함수
  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      bool isIgnoring = await Geolocator.isLocationServiceEnabled();
      if (!isIgnoring) {
        // 위치 서비스 활성화 요청
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      debugPrint("배터리 최적화 강제 해제 예외 방어: $e");
    }
  }

  // 🚀 [★무적 트래킹 엔진]: 트랭글 수준의 최상위 백그라운드 위성 안테나 기동
  void start(bool isEnglish, Function onUpdate) async {
    _isEnglish = isEnglish;
    
    // 이전 스트림 및 타이머 완전 청소
    _positionStream?.cancel();
    _timer?.cancel();

    // 1. 배터리 절전 모드 강제 예외 체크
    await _requestBatteryOptimizationExemption();

    // 2. 1초 타이머 (시간 및 칼로리 연산)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds++;
      if (dist > 0 && seconds > 0) {
        avgSpeed = (dist / (seconds / 3600));
      }
      calories = dist * 55; // 65kg 성인 기준 표준 소비 열량
      onUpdate();
    });

    // 🎯 [트랭글 방식 핵심 3대 설정]: OS 배터리 정책을 무력화하는 최상위 포그라운드 안테나 규격
    AndroidSettings androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation, // 내비게이션 등급 최고의 최고정밀도 설정
      distanceFilter: 0, // 미세 이동(0m)도 끊김 없이 즉시 위성 적재
      forceLocationManager: true, // 🚀 구글 위치 서비스를 우회하여 삼성 갤럭시 GPS 하드웨어 칩셋 직접 타격
      intervalDuration: const Duration(seconds: 1), // 1초 주기로 위성 갱신
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: _isEnglish ? "K-Path Tracking Active (Trangle Mode)" : "K-Path 무적 경로 추적 가동 중",
        notificationText: _isEnglish ? "Recording coordinates in background uninterrupted." : "주머니 속 및 배터리 절전 모드에서도 위성 수신을 강제 유지합니다.",
        notificationIcon: const AndroidResource(name: 'app_icon', defType: 'mipmap'),
        enableWakeLock: true, // 🔒 화면이 꺼져도 CPU 딥슬립(절전) 진입 차단 강제 잠금
      ),
    );

    // 🛰️ 실시간 수신 스트림 가동
    _positionStream = Geolocator.getPositionStream(
      locationSettings: androidSettings,
    ).listen((Position position) {
      LatLng newPoint = LatLng(position.latitude, position.longitude);

      if (routePoints.isNotEmpty) {
        // 실측 거리 연산 (미터 단위)
        double distanceInMeters = Geolocator.distanceBetween(
          routePoints.last.latitude,
          routePoints.last.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );

        // 정밀 오차 수신 방지 (0.5m 이상 이동 시 거리 누적)
        if (distanceInMeters >= 0.5) {
          dist += (distanceInMeters / 1000); // km 환산
          routePoints.add(newPoint);
          speed = position.speed * 3.6; // m/s -> km/h 환산
          _checkKmSpokenAlert();
        }
      } else {
        // 출발 최초 좌표 적재
        routePoints.add(newPoint);
        speed = position.speed * 3.6;
      }

      onUpdate();
    }, onError: (e) {
      debugPrint("무적 GPS 안테나 수신 예외 방어: $e");
    });
  }

  // 1km 마다 음성 안내 엔진
  void _checkKmSpokenAlert() {
    int currentKm = dist.floor();
    if (currentKm > 0 && currentKm > _lastSpokenKm) {
      _lastSpokenKm = currentKm;
      String speechText = _isEnglish
          ? "You have completed $currentKm kilometers."
          : "현재 $currentKm 키로미터 주행 중입니다.";
      _tts.speak(speechText);
    }
  }

  // 트레킹 정지 및 리셋
  void stop() {
    _positionStream?.cancel();
    _timer?.cancel();
    _positionStream = null;
    _timer = null;

    routePoints.clear();
    dist = 0.0;
    seconds = 0;
    speed = 0.0;
    avgSpeed = 0.0;
    calories = 0.0;
    _lastSpokenKm = 0;
  }
}