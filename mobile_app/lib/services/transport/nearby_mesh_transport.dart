
import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/models/mesh_packet.dart';
import '../../domain/models/node_entity.dart';
import 'mesh_transport.dart';

class NearbyMeshTransport implements MeshTransport {
static const MethodChannel _channel = MethodChannel('com.resqmesh.app/nearby_mesh');

String _localNodeId = 'NODE_UNKNOWN';
String _localDisplayName = 'ResQ Mesh Node';
String _statusMessage = 'Waiting for permissions...';
String _lastError = '';

@override
String get transportName => 'Google Nearby Connections (P2P_CLUSTER)';

@override
String get statusMessage => _statusMessage;

@override
String get lastError => _lastError;

bool _isRunning = false;
@override
bool get isRunning => _isRunning;

final _incomingPacketsController = StreamController<MeshPacket>.broadcast();
@override
Stream<MeshPacket> get incomingPackets => _incomingPacketsController.stream;

final _discoveredNodesController = StreamController<NodeEntity>.broadcast();
@override
Stream<NodeEntity> get discoveredNodes => _discoveredNodesController.stream;

final _peerDisconnectedController = StreamController<String>.broadcast();
@override
Stream<String> get peerDisconnected => _peerDisconnectedController.stream;

NearbyMeshTransport() {
_channel.setMethodCallHandler(_handleMethodCall);
}

Future<void> _handleMethodCall(MethodCall call) async {
switch (call.method) {
case 'onMeshStatus':
_statusMessage =
(call.arguments['message'] as String?) ?? 'Mesh status updated';
_lastError = '';
break;

case 'onMeshError':
_lastError =
(call.arguments['message'] as String?) ?? 'Unknown mesh error';
_statusMessage = _lastError;
break;

case 'onEndpointDiscovered':
final endpointId =
call.arguments['endpointId'] as String? ?? 'UNKNOWN';
final endpointName =
call.arguments['endpointName'] as String? ?? endpointId;

_statusMessage = 'Discovered nearby peer: $endpointName';

final node = NodeEntity(
nodeId: endpointId,
displayName: endpointName,
status: NodeConnectionStatus.available,
hopCount: 1,
rssi: null,
lastSeen: DateTime.now(),
batteryLevel: null,
transportType: NodeTransportType.wifiDirect,
);

_discoveredNodesController.add(node);
break;

case 'onEndpointConnected':
final endpointId =
call.arguments['endpointId'] as String? ?? 'UNKNOWN';

_statusMessage = 'Connected to peer: $endpointId';

final node = NodeEntity(
nodeId: endpointId,
displayName: endpointId,
status: NodeConnectionStatus.connected,
hopCount: 1,
rssi: null,
lastSeen: DateTime.now(),
batteryLevel: null,
transportType: NodeTransportType.wifiDirect,
);

_discoveredNodesController.add(node);
break;

case 'onEndpointDisconnected':
final endpointId =
call.arguments['endpointId'] as String? ?? 'UNKNOWN';

_statusMessage = 'Peer disconnected: $endpointId';
_peerDisconnectedController.add(endpointId);
break;

case 'onPayloadReceived':
final payload =
call.arguments['payload'] as String? ?? '';

if (payload.isEmpty) {
return;
}

try {
final packet = MeshPacket.deserialize(payload);
_incomingPacketsController.add(packet);
} catch (_) {
// Ignore malformed packet payloads.
}
break;
}
}

@override
Future<void> initialize(
String localNodeId,
String localDisplayName,
) async {
_localNodeId = localNodeId;
_localDisplayName = localDisplayName;
}

@override
Future<void> startDiscovery() async {
_isRunning = true;

try {
await _channel.invokeMethod('startMesh', {
'deviceId': _localNodeId,
'displayName': _localDisplayName,
'role': 'VICTIM',
'strategy': 'P2P_CLUSTER',
});
} catch (e) {
_isRunning = false;
_lastError = e.toString();
rethrow;
}
}

@override
Future<void> stopDiscovery() async {
_isRunning = false;

try {
await _channel.invokeMethod('stopMesh');
} catch (_) {}
}

@override
Future<void> startAdvertising() async {
// P2P_CLUSTER starts advertising and discovery together.
// Do not call startMesh() a second time.
}

@override
Future<void> stopAdvertising() async {
await stopDiscovery();
}

@override
Future<bool> connect(String nodeId) async {
// Nearby Connections auto-connects during discovery;
// keep existing behavior until native connection handling is verified.
return true;
}

@override
Future<void> disconnect(String nodeId) async {
try {
await _channel.invokeMethod('stopMesh');
} catch (_) {}
}

@override
Future<bool> sendPacket(
MeshPacket packet, {
String? targetEndpointId,
}) async {
try {
await _channel.invokeMethod('sendPayload', {
'payload': packet.serialize(),
'targetEndpointId': targetEndpointId,
'excludeEndpoint': null,
});

return true;
} catch (_) {
return false;
}
}

@override
void dispose() {
_incomingPacketsController.close();
_discoveredNodesController.close();
_peerDisconnectedController.close();
 }
 }
