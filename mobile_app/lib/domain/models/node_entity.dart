enum NodeConnectionStatus {
  connected,
  available,
  unreachable,
}

enum NodeTransportType {
  ble,
  wifiDirect,
  simulated,
}

class NodeEntity {
  final String nodeId;
  final String displayName;
  final NodeConnectionStatus status;
  final int hopCount;
  final int? rssi;
  final DateTime lastSeen;
  final int? batteryLevel;
  final NodeTransportType transportType;
  final List<String> intermediateHops;

  NodeEntity({
    required this.nodeId,
    required this.displayName,
    this.status = NodeConnectionStatus.available,
    this.hopCount = 1,
    this.rssi,
    required this.lastSeen,
    this.batteryLevel,
    this.transportType = NodeTransportType.ble,
    this.intermediateHops = const [],
  });

  bool get isDirectNeighbor => hopCount <= 1;

  NodeEntity copyWith({
    String? nodeId,
    String? displayName,
    NodeConnectionStatus? status,
    int? hopCount,
    int? rssi,
    DateTime? lastSeen,
    int? batteryLevel,
    NodeTransportType? transportType,
    List<String>? intermediateHops,
  }) {
    return NodeEntity(
      nodeId: nodeId ?? this.nodeId,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      hopCount: hopCount ?? this.hopCount,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      transportType: transportType ?? this.transportType,
      intermediateHops: intermediateHops ?? this.intermediateHops,
    );
  }

  Map<String, dynamic> toJson() => {
        'node_id': nodeId,
        'display_name': displayName,
        'status': status.name,
        'hop_count': hopCount,
        'rssi': rssi,
        'last_seen': lastSeen.toIso8601String(),
        'battery_level': batteryLevel,
        'transport_type': transportType.name,
        'intermediate_hops': intermediateHops,
      };

  factory NodeEntity.fromJson(Map<String, dynamic> json) => NodeEntity(
        nodeId: json['node_id'] as String,
        displayName: json['display_name'] as String? ?? 'Anonymous Node',
        status: NodeConnectionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => NodeConnectionStatus.available,
        ),
        hopCount: (json['hop_count'] as num?)?.toInt() ?? 1,
        rssi: (json['rssi'] as num?)?.toInt(),
        lastSeen: json['last_seen'] != null
            ? DateTime.tryParse(json['last_seen'] as String) ?? DateTime.now()
            : DateTime.now(),
        batteryLevel: (json['battery_level'] as num?)?.toInt(),
        transportType: NodeTransportType.values.firstWhere(
          (e) => e.name == json['transport_type'],
          orElse: () => NodeTransportType.ble,
        ),
        intermediateHops: (json['intermediate_hops'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}
