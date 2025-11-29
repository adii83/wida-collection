import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:winda_collection/services/location_service.dart';

/// Controller untuk Network Provider Location Tracker
/// Menggunakan network provider saja (tanpa GPS)
class NetworkLocationController extends GetxController {
  final LocationService _locationService = LocationService();

  // Observables
  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isTracking = false.obs;
  final Rx<LocationPermission> _permissionStatus =
      LocationPermission.denied.obs;

  // FlutterMap Controller
  MapController? _mapController;
  bool _isDisposed = false;

  // Map center position dan zoom
  final Rx<LatLng> _mapCenter = Rx<LatLng>(
    const LatLng(-6.2088, 106.8456), // Jakarta default
  );
  final RxDouble _mapZoom = 15.0.obs;

  // Stream subscription
  StreamSubscription<Position>? _positionSubscription;
  // ======== Experiment logging (Network) ========
  final RxBool _isRecording = false.obs;
  final RxList<Map<String, dynamic>> logs = <Map<String, dynamic>>[].obs;
  final RxList<LatLng> history = <LatLng>[].obs;

  DateTime? _lastUpdateTime;
  LatLng? _lastPosition;
  // Getters
  Position? get currentPosition => _currentPosition.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isTracking => _isTracking.value;
  bool get isRecording => _isRecording.value;
  LocationPermission get permissionStatus => _permissionStatus.value;
  MapController get mapController {
    if (_mapController == null || _isDisposed) {
      try {
        _mapController?.dispose();
      } catch (e) {
        // Ignore error saat dispose
      }
      _mapController = MapController();
      _isDisposed = false;
    }
    return _mapController!;
  }

  bool get isMapControllerReady => _mapController != null && !_isDisposed;
  LatLng get mapCenter => _mapCenter.value;
  double get mapZoom => _mapZoom.value;

  // Computed values
  double? get latitude => _currentPosition.value?.latitude;
  double? get longitude => _currentPosition.value?.longitude;
  double? get accuracy => _currentPosition.value?.accuracy;
  double? get altitude => _currentPosition.value?.altitude;
  double? get speed => _currentPosition.value?.speed;
  DateTime? get timestamp => _currentPosition.value?.timestamp;

  @override
  void onInit() {
    super.onInit();
    _isDisposed = false;
    try {
      _mapController?.dispose();
    } catch (e) {
      // Ignore error
    }
    _mapController = MapController();
    _initializeLocation();
  }

  /// Initialize permission state and try to load last known position
  Future<void> _initializeLocation() async {
    try {
      final status = await _locationService.checkPermission();
      _permissionStatus.value = status;

      if (kDebugMode) {
        print('📍 [NETWORK CONTROLLER] Initial permission: $status');
      }

      // Try to get last known position (cached) to show something quickly
      await getLastKnownPosition();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] _initializeLocation error: $e');
      }
    }
  }

  // =========================================================
  //             EXPERIMENT RECORDING (NETWORK)
  // =========================================================

  void startRecording() {
    logs.clear();
    history.clear();
    _lastUpdateTime = null;
    _lastPosition = null;
    _isRecording.value = true;

    if (kDebugMode) {
      print('🧪 [NET] Recording started');
    }

    Get.snackbar(
      'Recording dimulai',
      'Aplikasi sedang merekam data Network Provider',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> stopRecording() async {
    _isRecording.value = false;

    if (logs.isEmpty) {
      Get.snackbar(
        'Tidak ada data',
        'Belum ada data yang terekam',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _exportCsv();
  }

  Future<void> _exportCsv() async {
    try {
      final buffer = StringBuffer();

      buffer.writeln('time,lat,lng,accuracy,delay_sec,distance_m,speed_m_s');

      for (final log in logs) {
        buffer.writeln(
          '${log['time']},'
          '${log['lat']},'
          '${log['lng']},'
          '${log['accuracy']},'
          '${log['delay_sec']},'
          '${log['distance_m']},'
          '${log['speed_m_s']}',
        );
      }

      final filename =
          'network_experiment_${DateTime.now().millisecondsSinceEpoch}.csv';

      final file = File('/storage/emulated/0/Download/$filename');

      await file.writeAsString(buffer.toString());

      Get.snackbar(
        'CSV disimpan',
        'File: $filename (folder Download)',
        snackPosition: SnackPosition.BOTTOM,
      );

      if (kDebugMode) {
        print('🧪 [NET] CSV exported to ${file.path}');
      }
    } catch (e) {
      Get.snackbar(
        'Gagal export CSV',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      if (kDebugMode) {
        print('❌ [NET] CSV export error: $e');
      }
    }
  }

  void _logExperiment(Position pos) {
    if (!_isRecording.value) return;

    final currentTime = DateTime.now();

    final delay = _lastUpdateTime == null
        ? 0.0
        : currentTime.difference(_lastUpdateTime!).inMilliseconds / 1000;

    final currentLatLng = LatLng(pos.latitude, pos.longitude);

    final distance = _lastPosition == null
        ? 0.0
        : Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            pos.latitude,
            pos.longitude,
          );

    final speed = delay == 0 ? 0.0 : distance / delay;

    logs.add({
      'time': currentTime.toIso8601String(),
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy,
      'delay_sec': delay,
      'distance_m': distance,
      'speed_m_s': speed,
    });

    history.add(currentLatLng);

    _lastUpdateTime = currentTime;
    _lastPosition = currentLatLng;

    if (kDebugMode) {
      print(
        '🧪 [NET] log -> acc: ${pos.accuracy}, delay: $delay, dist: $distance, speed: $speed',
      );
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    _stopTracking();
    _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      _mapController?.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing map controller: $e');
      }
    } finally {
      _mapController = null;
    }

    super.onClose();
  }

  bool _canUseMapController() {
    return !_isDisposed && _mapController != null;
  }

  Future<void> getCurrentPosition() async {
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('🌐 [NETWORK CONTROLLER] getCurrentPosition() (STREAM MODE)');
      print('🌐 [NETWORK CONTROLLER] Using NETWORK provider only');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Cek permission dulu
      bool hasPermission = await _locationService.isPermissionGranted();
      if (!hasPermission) {
        await requestPermission();
        hasPermission = await _locationService.isPermissionGranted();
      }

      if (!hasPermission) {
        throw PermissionDeniedException('Location permission denied');
      }

      // 🔥 STOP STREAM LAMA
      _positionSubscription?.cancel();
      _positionSubscription = null;

      // 🔥 MULAI STREAM NETWORK-ONLY
      final stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // NETWORK MODE
          distanceFilter: 5, // Update jika bergerak ≥ 5 meter
        ),
      );

      _positionSubscription = stream.listen(
        (Position pos) {
          _currentPosition.value = pos;

          // Update map + polyline
          _updateMapPosition(pos);

          // Logging eksperimen
          _logExperiment(pos);

          if (kDebugMode) {
            print(
              '🌐 [STREAM] NET Update -> lat:${pos.latitude}, lng:${pos.longitude}, acc:${pos.accuracy}',
            );
          }
        },
        onError: (err) {
          _errorMessage.value = err.toString();
          if (kDebugMode) {
            print('❌ [STREAM ERROR] $err');
          }
        },
      );

      _isTracking.value = true; // TRACKING SELALU AKTIF
    } catch (e, stackTrace) {
      _errorMessage.value = e.toString();

      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Error: $e');
        print('❌ Stack Trace: $stackTrace');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> getLastKnownPosition() async {
    try {
      Position? position = await _locationService.getLastKnownPosition();

      if (position != null) {
        _currentPosition.value = position;
        _updateMapPosition(position);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get last known position error: $e');
      }
    }
  }

  /// Request permission via LocationService and update controller state
  /// [requireGps] forwarded to LocationService (default false -> network)
  Future<bool> requestPermission({bool requireGps = false}) async {
    final result = await _locationService.requestPermission(
      requireGps: requireGps,
    );
    try {
      _permissionStatus.value = await _locationService.checkPermission();
    } catch (_) {}
    return result;
  }

  /// Open app settings (delegates to LocationService)
  Future<void> openAppSettings() async {
    try {
      await _locationService.openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('Error opening app settings: $e');
      }
    }
  }

  Future<void> startTracking() async {
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('🌐 [NETWORK CONTROLLER] startTracking() called');
      print('🌐 [NETWORK CONTROLLER] useGps parameter: false (NETWORK ONLY)');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
      // Cek permission dulu
      bool hasPermission = await _locationService.isPermissionGranted();
      if (!hasPermission) {
        // Request permission jika belum granted
        if (kDebugMode) {
          print(
            '🌐 [NETWORK CONTROLLER] Requesting permission (requireGps: false)',
          );
        }
        hasPermission = await _locationService.requestPermission(
          requireGps: false, // Network provider tidak perlu GPS - HARUS FALSE
        );
      }

      if (!hasPermission) {
        // Throw exception dengan message dari permission status
        final status = await _locationService.checkPermission();
        if (status == LocationPermission.deniedForever) {
          throw PermissionDeniedException(
            'Location permission permanently denied',
          );
        } else {
          throw PermissionDeniedException('Location permission denied');
        }
      }

      _isTracking.value = true;
      _errorMessage.value = '';

      if (kDebugMode) {
        print(
          '🌐 [NETWORK CONTROLLER] Starting position stream (useGps: false)',
        );
      }

      Stream<Position>? positionStream = _locationService.getPositionStream(
        useGps: false, // Selalu network provider - HARUS FALSE
        distanceFilter: 10,
      );

      if (positionStream != null) {
        _positionSubscription?.cancel();
        _positionSubscription = positionStream.listen(
          (Position position) {
            _currentPosition.value = position;
            _updateMapPosition(position);
            _logExperiment(position);
          },
          onError: (error) {
            // Gunakan error message asli dari sistem
            _errorMessage.value = error.toString();
            if (kDebugMode) {
              print(
                '❌ [NETWORK CONTROLLER] Position stream error: ${error.toString()}',
              );
            }
          },
        );
      } else {
        throw Exception(
          'Failed to start position stream: Position stream is null',
        );
      }
    } on PermissionDeniedException catch (e) {
      // Gunakan error message asli dari sistem
      _errorMessage.value = e.toString();
      _isTracking.value = false;
      if (kDebugMode) {
        print(
          '❌ [NETWORK CONTROLLER] PermissionDeniedException: ${e.toString()}',
        );
      }
    } on LocationServiceDisabledException catch (e) {
      // Gunakan error message asli dari sistem
      _errorMessage.value = e.toString();
      _isTracking.value = false;
      if (kDebugMode) {
        print(
          '❌ [NETWORK CONTROLLER] LocationServiceDisabledException: ${e.toString()}',
        );
      }
    } on TimeoutException catch (e) {
      // Gunakan error message asli dari sistem
      _errorMessage.value = e.toString();
      _isTracking.value = false;
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] TimeoutException: ${e.toString()}');
      }
    } catch (e, stackTrace) {
      // Gunakan error message asli dari sistem
      _errorMessage.value = e.toString();
      _isTracking.value = false;
      if (kDebugMode) {
        print('❌ [NETWORK CONTROLLER] Start tracking error: ${e.toString()}');
        print('❌ [NETWORK CONTROLLER] Stack trace: $stackTrace');
      }
    }
  }

  void _stopTracking() {
    _isTracking.value = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationService.stopPositionStream();
  }

  void stopTracking() {
    _stopTracking();
  }

  void _updateMapPosition(Position position) {
    if (_isDisposed || !_canUseMapController()) return;

    final newCenter = LatLng(position.latitude, position.longitude);
    _mapCenter.value = newCenter;

    try {
      _mapController?.move(newCenter, _mapZoom.value);
    } catch (e) {
      if (kDebugMode) {
        print('Map controller not ready yet: $e');
      }
    }
  }

  void updateMapCenter(LatLng center, double zoom) {
    if (_isDisposed) return;
    _mapCenter.value = center;
    _mapZoom.value = zoom;
  }

  void setZoom(double zoom) {
    if (_isDisposed || !_canUseMapController()) return;

    _mapZoom.value = zoom;
    if (_currentPosition.value != null) {
      try {
        _mapController?.move(
          LatLng(
            _currentPosition.value!.latitude,
            _currentPosition.value!.longitude,
          ),
          zoom,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Map controller not ready for zoom: $e');
        }
      }
    }
  }

  void zoomIn() {
    final newZoom = (_mapZoom.value + 1).clamp(3.0, 18.0);
    setZoom(newZoom);
  }

  void zoomOut() {
    final newZoom = (_mapZoom.value - 1).clamp(3.0, 18.0);
    setZoom(newZoom);
  }

  void moveToCurrentPosition() {
    if (_isDisposed || !_canUseMapController()) return;

    if (_currentPosition.value != null) {
      try {
        final position = _currentPosition.value!;
        final center = LatLng(position.latitude, position.longitude);
        _mapController?.move(center, _mapZoom.value);
        _mapCenter.value = center;
      } catch (e) {
        if (kDebugMode) {
          print('Map controller not ready for move: $e');
        }
      }
    }
  }

  Future<void> refreshPosition() async {
    await getCurrentPosition();
  }

  void resetMapController() {
    try {
      _mapController?.dispose();
    } catch (e) {
      // Ignore error
    }
    _mapController = MapController();
    _isDisposed = false;
  }

  Future<void> toggleTracking() async {
    if (_isTracking.value) {
      stopTracking();
    } else {
      await startTracking();
    }
  }

  /// Get error action button info berdasarkan konteks error
  Map<String, dynamic> getErrorAction() {
    final error = _errorMessage.value.toLowerCase();

    // Permission permanently denied - buka app settings
    if (error.contains('permanently denied') ||
        error.contains('deniedforever')) {
      return {
        'label': 'Buka Pengaturan',
        'icon': Icons.settings,
        'action': openAppSettings,
      };
    }

    // Permission denied - request permission
    if (error.contains('permission denied') || error.contains('permission')) {
      return {
        'label': 'Berikan Izin Lokasi',
        'icon': Icons.location_on,
        'action': requestPermission,
      };
    }

    // Network unavailable atau timeout
    if (error.contains('timeout') ||
        error.contains('network') ||
        error.contains('unavailable')) {
      return {
        'label': 'Coba Lagi',
        'icon': Icons.refresh,
        'action': getCurrentPosition,
      };
    }

    // General error - retry
    return {
      'label': 'Coba Lagi',
      'icon': Icons.refresh,
      'action': getCurrentPosition,
    };
  }
}
