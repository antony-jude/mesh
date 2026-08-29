import 'dart:convert';
import '../../core/utils/crypto_utils.dart';

enum PacketType {
  chat,
  emergency,
  ack,
  heartbeat,
  sync,
}

class MeshPacket {
  final String packetId;
  final PacketType type;
  final String senderId;
  final String senderName;
  final String receiverId; // Specific Node ID or '*' for Broadcast
  final DateTime timestamp;
  final String payload;
  int ttl;
  int hopCount;
  final List<String> hopPath;
  final bool encrypted;
  final String? signature;

  MeshPacket({
    required this.packetId,
    required this.type,
    required this.senderId,
    this.senderName = 'Node',
    required this.receiverId,
    DateTime? timestamp,
    required this.payload,
    this.ttl = 10,
    this.hopCount = 0,
    List<String>? hopPath,
    this.encrypted = true,
    this.signature,
  })  : timestamp = timestamp ?? DateTime.now(),
        hopPath = hopPath ?? [senderId];

  bool get isBroadcast => receiverId == '*' || receiverId == 'BROADCAST';
  bool get isExpired => ttl <= 0;

  /// Increment hop count and decrement TTL upon relay
  bool relay(String currentRelayNodeId) {
    if (isExpired) return false;
    ttl -= 1;
    hopCount += 1;
    if (!hopPath.contains(currentRelayNodeId)) {
      hopPath.add(currentRelayNodeId);
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'packetId': packetId,
        'type': type.name,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload,
        'ttl': ttl,
        'hopCount': hopCount,
        'hopPath': hopPath,
        'encrypted': encrypted,
        'signature': signature ?? CryptoUtils.calculateHmac(packetId + senderId + receiverId),
      };

  factory MeshPacket.fromJson(Map<String, dynamic> json) => MeshPacket(
        packetId: json['packetId'] as String,
        type: PacketType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => PacketType.chat,
        ),
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String? ?? 'Node',
        receiverId: json['receiverId'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now(),
        payload: json['payload'] as String,
        ttl: (json['ttl'] as num?)?.toInt() ?? 10,
        hopCount: (json['hopCount'] as num?)?.toInt() ?? 0,
        hopPath: (json['hopPath'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        encrypted: json['encrypted'] as bool? ?? true,
        signature: json['signature'] as String?,
      );

  String serialize() => jsonEncode(toJson());

  static MeshPacket deserialize(String rawJson) {
    final map = jsonDecode(rawJson) as Map<String, dynamic>;
    return MeshPacket.fromJson(map);
  }
}
