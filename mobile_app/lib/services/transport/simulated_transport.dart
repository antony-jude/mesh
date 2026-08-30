import 'dart:async';
import '../../domain/models/mesh_packet.dart';
import '../../domain/models/node_entity.dart';
import 'mesh_transport.dart';

class SimulatedMeshTransport implements MeshTransport {
  @override
  String get transportName => 'Simulated Multi-Node Mesh (Demo)';

  @override
  String get statusMessage => 'Simulation mode active';

  @override
  String get lastError => '';

  bool _isRunning = false;
  @override
  bool get isRunning => _isRunning;

  late String _localNodeId;
  late String _localDisplayName;

  final _incomingPacketsController = StreamController<MeshPacket>.broadcast();
  @override
  Stream<MeshPacket> get incomingPackets => _incomingPacketsController.stream;

  final _discoveredNodesController = StreamController<NodeEntity>.broadcast();
  @override
  Stream<NodeEntity> get discoveredNodes => _discoveredNodesController.stream;

  final _peerDisconnectedController = StreamController<String>.broadcast();
  @override
  Stream<String> get peerDisconnected => _peerDisconnectedController.stream;

  final Set<String> _connectedPeers = {'NODE-B21A', 'NODE-C49F'};

  @override
  Future<void> initialize(String localNodeId, String localDisplayName) async {
    _localNodeId = localNodeId;
    _localDisplayName = localDisplayName;
  }

  @override
  Future<void> startDiscovery() async {
    _isRunning = true;
  }

  @override
  Future<void> stopDiscovery() async {
    _isRunning = false;
  }

  @override
  Future<void> startAdvertising() async {
    _isRunning = true;
  }

  @override
  Future<void> stopAdvertising() async {
    _isRunning = false;
  }

  @override
  Future<bool> connect(String nodeId) async {
    _connectedPeers.add(nodeId);
    return true;
  }

  @override
  Future<void> disconnect(String nodeId) async {
    _connectedPeers.remove(nodeId);
    _peerDisconnectedController.add(nodeId);
  }

  @override
  Future<bool> sendPacket(MeshPacket packet, {String? targetEndpointId}) async {
    // In simulated environment: if sending to Node D via B and C
    if (packet.receiverId == 'NODE-D83E' || packet.isBroadcast) {
      // Simulate multi-hop propagation: A -> B -> C -> D
      _simulateMultiHopHopDelivery(packet);
    }
    return true;
  }

  void _simulateMultiHopHopDelivery(MeshPacket packet) async {
    // Hop 1: Node B receives
    await Future.delayed(const Duration(milliseconds: 600));
    final hop1 = MeshPacket(
      packetId: packet.packetId,
      type: packet.type,
      senderId: packet.senderId,
      senderName: packet.senderName,
      receiverId: packet.receiverId,
      payload: packet.payload,
      ttl: packet.ttl - 1,
      hopCount: packet.hopCount + 1,
      hopPath: [...packet.hopPath, 'NODE-B21A'],
    );

    // If Node D receives
    await Future.delayed(const Duration(milliseconds: 700));
    final ackPacket = MeshPacket(
      packetId: 'ack_${packet.packetId}',
      type: PacketType.ack,
      senderId: packet.receiverId,
      senderName: 'Base Station Delta',
      receiverId: packet.senderId,
      payload: 'ACK_DELIVERED',
      ttl: 10,
      hopCount: 2,
      hopPath: ['NODE-D83E', 'NODE-B21A', _localNodeId],
    );

    _incomingPacketsController.add(ackPacket);
  }

  /// Inject an incoming packet for demo purposes
  void injectPacket(MeshPacket packet) {
    _incomingPacketsController.add(packet);
  }

  @override
  void dispose() {
    _incomingPacketsController.close();
    _discoveredNodesController.close();
    _peerDisconnectedController.close();
  }
}
