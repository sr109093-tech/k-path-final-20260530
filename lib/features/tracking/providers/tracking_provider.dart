import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>(
  (ref) => TrackingNotifier(),
);

class TrackingState {
  final bool isTracking;
  final Position? currentPosition;
  final List<LatLng> routePoints;
  final Polyline? currentPolyline;
  final double totalDistance;
  final String? lastSavedTrackPath;   // 저장된 파일 경로

  TrackingState({
    this.isTracking = false,
    this.currentPosition,
    this.routePoints = const [],
    this.currentPolyline,
    this.totalDistance = 0.0,
    this.lastSavedTrackPath,
  });

  TrackingState copyWith({
    bool? isTracking,
    Position? currentPosition,
    List<LatLng>? routePoints,
    Polyline? currentPolyline,
    double? totalDistance,
    String? lastSavedTrackPath,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      currentPosition: currentPosition ?? this.currentPosition,
      routePoints: routePoints ?? this.routePoints,
      currentPolyline: currentPolyline ?? this.currentPolyline,
      totalDistance: totalDistance ?? this.totalDistance,
      lastSavedTrackPath: lastSavedTrackPath ?? this.lastSavedTrackPath,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(TrackingState());

  StreamSubscription<Position>? _positionSubscription;
  GoogleMapController? _mapController;   // ← 카메라 제어용

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    state = state.copyWith(
      isTracking: true,
      routePoints: [],
      totalDistance: 0.0,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);
      final updatedPoints = [...state.routePoints, newPoint];

      double newDistance = state.totalDistance;
      if (state.routePoints.isNotEmpty) {
        newDistance += Geolocator.distanceBetween(
          state.routePoints.last.latitude,
          state.routePoints.last.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );
      }

      final polyline = Polyline(
        polylineId: const PolylineId('tracking_route'),
        points: updatedPoints,
        color: Colors.red,
        width: 6,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      // 카메라 자동 따라가기
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(newPoint),
      );

      state = state.copyWith(
        currentPosition: position,
        routePoints: updatedPoints,
        currentPolyline: polyline,
        totalDistance: newDistance,
      );
    });
  }

  Future<void> stopTracking() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    if (state.routePoints.length > 1) {
      final savedPath = await _saveTrackToFile();
      state = state.copyWith(
        isTracking: false,
        lastSavedTrackPath: savedPath,
      );
    } else {
      state = state.copyWith(isTracking: false);
    }
  }

  Future<String?> _saveTrackToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'track_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      final trackData = {
        'date': DateTime.now().toIso8601String(),
        'totalDistance': state.totalDistance,
        'points': state.routePoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      };

      await file.writeAsString(jsonEncode(trackData));

      print('✅ 트랙 저장 완료: ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ 트랙 저장 실패: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}