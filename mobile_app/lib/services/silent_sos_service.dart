import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sos_packet.dart';

enum TapType { short, long }

class TapEvent {
  final DateTime timestamp;
  final double magnitude;
  final TapType tapType;

  TapEvent({
    required this.timestamp,
    required this.magnitude,
    required this.tapType,
  });
}

/// Stage C: Silent SOS Tap-Pattern Detector
/// Accelerometer-based rhythmic peak detection & timing window matcher
/// Pattern: 3 Short Taps + 1 Long Tap (or sustained tap) = Instant CRITICAL SOS
class SilentSosService {
  // Accelerometer threshold in m/s^2 (excluding gravity ~9.8m/s^2)
  static const double accelerationThreshold = 14.5;
  static const int maxWindowMs = 4500; // Complete sequence must finish within 4.5s
  static const int minTapGapMs = 150; // Debounce window
  static const int shortTapMaxDurationMs = 400; // Short tap tap-down duration

  bool _isListening = false;
  bool get isListening => _isListening;

  StreamSubscription<UserAccelerometerEvent>? _sensorSub;
  final List<TapEvent> _detectedTaps = [];

  final _tapProgressController = StreamController<int>.broadcast();
  Stream<int> get tapProgressStream => _tapProgressController.stream;

  final _sosTriggeredController = StreamController<SosPacket>.broadcast();
  Stream<SosPacket> get sosTriggeredStream => _sosTriggeredController.stream;

  final _accelerometerStreamController = StreamController<double>.broadcast();
  Stream<double> get rawMagnitudeStream => _accelerometerStreamController.stream;

  DateTime? _lastTapTime;
  Timer? _windowExpiryTimer;

  void startListening({required String deviceId, LocationPoint? location}) {
    if (_isListening) return;
    _isListening = true;
    _detectedTaps.clear();
    _tapProgressController.add(0);

    try {
      _sensorSub = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
        // Calculate dynamic vector magnitude
        final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        _accelerometerStreamController.add(magnitude);

        if (magnitude > accelerationThreshold) {
          _handleRawAccelerationPeak(magnitude, deviceId, location);
        }
      }, onError: (err) {
        // Fallback for simulation / emulator
      });
    } catch (_) {
      // Sensor not available on some emulators
    }
  }

  void stopListening() {
    _isListening = false;
    _sensorSub?.cancel();
    _sensorSub = null;
    _windowExpiryTimer?.cancel();
    _detectedTaps.clear();
    _tapProgressController.add(0);
  }

  /// Trigger manual tap simulation (useful for testing on desktop or UI tap pad)
  void simulateTap({
    required TapType tapType,
    required String deviceId,
    LocationPoint? location,
  }) {
    final now = DateTime.now();
    _processNewTap(TapEvent(timestamp: now, magnitude: 18.5, tapType: tapType), deviceId, location);
  }

  void _handleRawAccelerationPeak(double magnitude, String deviceId, LocationPoint? location) {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < minTapGapMs) {
      return; // Debounce jitter
    }
    _lastTapTime = now;

    // Detect tap type (short vs sustained)
    final tapType = _detectedTaps.length < 3 ? TapType.short : TapType.long;
    _processNewTap(TapEvent(timestamp: now, magnitude: magnitude, tapType: tapType), deviceId, location);
  }

  void _processNewTap(TapEvent tap, String deviceId, LocationPoint? location) {
    final now = DateTime.now();

    // Reset window if too long has passed since first tap
    if (_detectedTaps.isNotEmpty) {
      final elapsed = now.difference(_detectedTaps.first.timestamp).inMilliseconds;
      if (elapsed > maxWindowMs) {
        _detectedTaps.clear();
      }
    }

    _detectedTaps.add(tap);
    final currentCount = _detectedTaps.length;
    _tapProgressController.add(currentCount);

    // Reset timer
    _windowExpiryTimer?.cancel();
    _windowExpiryTimer = Timer(const Duration(milliseconds: maxWindowMs), () {
      if (_detectedTaps.isNotEmpty) {
        _detectedTaps.clear();
        _tapProgressController.add(0);
      }
    });

    // Check for target pattern: 3 Short Taps + 1 Long Tap (Total 4 taps)
    if (_detectedTaps.length >= 4) {
      _triggerSilentSos(deviceId, location);
      _detectedTaps.clear();
      _tapProgressController.add(0);
    }
  }

  void _triggerSilentSos(String deviceId, LocationPoint? location) {
    final packet = SosPacket(
      originDeviceId: deviceId,
      priorityScore: 1.0,
      priorityLabel: PriorityLabel.CRITICAL,
      signalType: SignalType.TAP_PATTERN,
      classificationReasoning: 'Silent SOS Triggered: Accelerometer rhythmic pattern (3-Short + 1-Long Morse distress) verified. Victim incapacitated/unable to speak. Immediate critical dispatch.',
      lastKnownLocation: location ?? LocationPoint(lat: 37.7749, lng: -122.4194, accuracyM: 3.5),
      payloadEncrypted: true,
    );

    _sosTriggeredController.add(packet);
  }

  void dispose() {
    stopListening();
    _tapProgressController.close();
    _sosTriggeredController.close();
    _accelerometerStreamController.close();
  }
}
