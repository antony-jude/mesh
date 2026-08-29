import 'dart:async';
import '../../domain/models/node_entity.dart';
import '../../domain/repositories/i_node_repository.dart';

class NodeRepositoryImpl implements INodeRepository {
  final Map<String, NodeEntity> _nodes = {};
  final _nodesStreamController = StreamController<List<NodeEntity>>.broadcast();

  NodeRepositoryImpl() {
    _initDefaultPeers();
  }

  void _initDefaultPeers() {
    final now = DateTime.now();
    final defaultNodes = [
      NodeEntity(
        nodeId: 'NODE-B21A',
        displayName: 'Alpha Responder',
        status: NodeConnectionStatus.connected,
        hopCount: 1,
        rssi: -58,
        lastSeen: now,
        batteryLevel: 84,
        transportType: NodeTransportType.ble,
      ),
      NodeEntity(
        nodeId: 'NODE-C49F',
        displayName: 'Field Team Beta',
        status: NodeConnectionStatus.connected,
        hopCount: 1,
        rssi: -66,
        lastSeen: now,
        batteryLevel: 72,
        transportType: NodeTransportType.ble,
      ),
      NodeEntity(
        nodeId: 'NODE-D83E',
        displayName: 'Base Station Delta',
        status: NodeConnectionStatus.available,
        hopCount: 2,
        rssi: -79,
        lastSeen: now.subtract(const Duration(minutes: 2)),
        batteryLevel: 95,
        transportType: NodeTransportType.ble,
        intermediateHops: ['NODE-B21A'],
      ),
      NodeEntity(
        nodeId: 'NODE-E51B',
        displayName: 'Shelter Hub Echo',
        status: NodeConnectionStatus.available,
        hopCount: 3,
        lastSeen: now.subtract(const Duration(minutes: 6)),
        batteryLevel: 60,
        transportType: NodeTransportType.wifiDirect,
        intermediateHops: ['NODE-B21A', 'NODE-D83E'],
      ),
    ];

    for (final node in defaultNodes) {
      _nodes[node.nodeId] = node;
    }
    _notify();
  }

  void _notify() {
    _nodesStreamController.add(_nodes.values.toList()
      ..sort((a, b) => a.hopCount.compareTo(b.hopCount)));
  }

  @override
  Future<List<NodeEntity>> getDiscoveredNodes() async {
    return _nodes.values.toList()
      ..sort((a, b) => a.hopCount.compareTo(b.hopCount));
  }

  @override
  Future<NodeEntity?> getNode(String nodeId) async {
    return _nodes[nodeId];
  }

  @override
  Future<void> saveOrUpdateNode(NodeEntity node) async {
    _nodes[node.nodeId] = node;
    _notify();
  }

  @override
  Future<void> removeNode(String nodeId) async {
    _nodes.remove(nodeId);
    _notify();
  }

  @override
  Future<void> updateNodeStatus(String nodeId, NodeConnectionStatus status) async {
    final existing = _nodes[nodeId];
    if (existing != null) {
      _nodes[nodeId] = existing.copyWith(status: status, lastSeen: DateTime.now());
      _notify();
    }
  }

  @override
  Stream<List<NodeEntity>> watchNodes() => _nodesStreamController.stream;

  void dispose() {
    _nodesStreamController.close();
  }
}
