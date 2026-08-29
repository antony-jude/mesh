import 'dart:async';
import '../../domain/models/mesh_packet.dart';
import '../../domain/models/node_entity.dart';

abstract class MeshTransport {
  String get transportName;
  bool get isRunning;

  Future<void> initialize(String localNodeId, String localDisplayName);
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> startAdvertising();
  Future<void> stopAdvertising();
  
  Future<bool> connect(String nodeId);
  Future<void> disconnect(String nodeId);
  Future<bool> sendPacket(MeshPacket packet, {String? targetEndpointId});
  
  Stream<MeshPacket> get incomingPackets;
  Stream<NodeEntity> get discoveredNodes;
  Stream<String> get peerDisconnected;
  
  void dispose();
}
