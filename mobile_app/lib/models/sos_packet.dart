import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:uuid/uuid.dart';

enum PriorityLabel {
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL,
}

enum SignalType {
  ACOUSTIC,
  TAP_PATTERN,
  MANUAL,
}

enum DeviceRole {
  VICTIM,
  RELAY,
  GATEWAY,
}

class LocationPoint {
  final double lat;
  final double lng;
  final double accuracyM;

  LocationPoint({
    required this.lat,
    required this.lng,
    this.accuracyM = 5.0,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      accuracyM: (json['accuracy_m'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'accuracy_m': accuracyM,
      };
}

class SosPacket {
  final String packetId;
  final String originDeviceId;
  final DateTime timestamp;
  int hopCount;
  final List<String> hopPath;
  final double priorityScore;
  final PriorityLabel priorityLabel;
  final SignalType signalType;
  final String classificationReasoning;
  final LocationPoint lastKnownLocation;
  final bool payloadEncrypted;
  final String? encryptedPayload;

  // Pre-shared 256-bit demo AES key for offline mesh demonstration
  // NOTE: In production deployment, replace with dynamic X3DH/Double Ratchet session keys.
  static const String demoAesKey = 'ResQMeshSecretKey2026SecureAES32B'; // 32 chars = 256 bits
  static const String demoIv = 'ResQMeshDemoIV16'; // 16 chars = 128 bits

  SosPacket({
    String? packetId,
    required this.originDeviceId,
    DateTime? timestamp,
    this.hopCount = 0,
    List<String>? hopPath,
    required this.priorityScore,
    required this.priorityLabel,
    required this.signalType,
    required this.classificationReasoning,
    required this.lastKnownLocation,
    this.payloadEncrypted = true,
    this.encryptedPayload,
  })  : packetId = packetId ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now().toUtc(),
        hopPath = hopPath ?? [originDeviceId];

  /// Increment hop count and append current relay device ID to the hop path
  void incrementHop(String relayDeviceId) {
    hopCount += 1;
    if (!hopPath.contains(relayDeviceId)) {
      hopPath.add(relayDeviceId);
    }
  }

  /// Serialize packet to JSON format adhering to Phase 1 specs
  Map<String, dynamic> toJson() {
    return {
      'packet_id': packetId,
      'origin_device_id': originDeviceId,
      'timestamp': timestamp.toIso8601String(),
      'hop_count': hopCount,
      'hop_path': hopPath,
      'priority_score': priorityScore,
      'priority_label': priorityLabel.name,
      'signal_type': signalType.name,
      'classification_reasoning': classificationReasoning,
      'last_known_location': lastKnownLocation.toJson(),
      'payload_encrypted': payloadEncrypted,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
    };
  }

  /// Encrypt internal payload data using AES-256
  String exportEncryptedPacket() {
    final rawJson = jsonEncode(toJson());
    final key = enc.Key.fromUtf8(demoAesKey);
    final iv = enc.IV.fromUtf8(demoIv);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(rawJson, iv: iv);
    
    // Envelope format sent over Nearby Connections
    return jsonEncode({
      'envelope_version': '1.0',
      'packet_id': packetId,
      'payload_encrypted': true,
      'cipher_text': encrypted.base64,
      'hmac': sha256.convert(utf8.encode(encrypted.base64)).toString(),
    });
  }

  /// Decrypt incoming envelope packet from mesh
  static SosPacket fromEncryptedPayload(String payloadString) {
    try {
      final decodedMap = jsonDecode(payloadString) as Map<String, dynamic>;
      
      // If payload is already raw JSON
      if (decodedMap.containsKey('origin_device_id')) {
        return SosPacket.fromJson(decodedMap);
      }

      // If payload is encrypted envelope
      if (decodedMap.containsKey('cipher_text')) {
        final cipherBase64 = decodedMap['cipher_text'] as String;
        final key = enc.Key.fromUtf8(demoAesKey);
        final iv = enc.IV.fromUtf8(demoIv);
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        final decryptedText = encrypter.decrypt64(cipherBase64, iv: iv);
        final decryptedJson = jsonDecode(decryptedText) as Map<String, dynamic>;
        return SosPacket.fromJson(decryptedJson);
      }

      throw FormatException('Unrecognized packet envelope format');
    } catch (e) {
      throw FormatException('Failed to decrypt and deserialize SOS packet: $e');
    }
  }

  factory SosPacket.fromJson(Map<String, dynamic> json) {
    return SosPacket(
      packetId: json['packet_id'] as String? ?? const Uuid().v4(),
      originDeviceId: json['origin_device_id'] as String? ?? 'UNKNOWN_DEV',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now().toUtc()
          : DateTime.now().toUtc(),
      hopCount: (json['hop_count'] as num?)?.toInt() ?? 0,
      hopPath: (json['hop_path'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0.5,
      priorityLabel: PriorityLabel.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['priority_label'] as String? ?? 'MEDIUM').toUpperCase(),
        orElse: () => PriorityLabel.MEDIUM,
      ),
      signalType: SignalType.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['signal_type'] as String? ?? 'ACOUSTIC').toUpperCase(),
        orElse: () => SignalType.ACOUSTIC,
      ),
      classificationReasoning: json['classification_reasoning'] as String? ?? 'No reasoning provided.',
      lastKnownLocation: LocationPoint.fromJson(
        json['last_known_location'] as Map<String, dynamic>? ?? {'lat': 0.0, 'lng': 0.0, 'accuracy_m': 5.0},
      ),
      payloadEncrypted: json['payload_encrypted'] as bool? ?? true,
      encryptedPayload: json['encrypted_payload'] as String?,
    );
  }

  SosPacket copyWith({
    String? packetId,
    String? originDeviceId,
    DateTime? timestamp,
    int? hopCount,
    List<String>? hopPath,
    double? priorityScore,
    PriorityLabel? priorityLabel,
    SignalType? signalType,
    String? classificationReasoning,
    LocationPoint? lastKnownLocation,
    bool? payloadEncrypted,
    String? encryptedPayload,
  }) {
    return SosPacket(
      packetId: packetId ?? this.packetId,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      timestamp: timestamp ?? this.timestamp,
      hopCount: hopCount ?? this.hopCount,
      hopPath: hopPath ?? List.from(this.hopPath),
      priorityScore: priorityScore ?? this.priorityScore,
      priorityLabel: priorityLabel ?? this.priorityLabel,
      signalType: signalType ?? this.signalType,
      classificationReasoning: classificationReasoning ?? this.classificationReasoning,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      payloadEncrypted: payloadEncrypted ?? this.payloadEncrypted,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
    );
  }
}
