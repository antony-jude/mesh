import 'package:flutter/material.dart';
import '../../domain/models/emergency_payload.dart';
import '../../domain/models/message_entity.dart';
import '../../domain/models/node_entity.dart';
import '../../services/mesh_network_manager.dart';
import '../../services/routing/routing_engine.dart';

class MeshStateProvider extends ChangeNotifier {
  final MeshNetworkManager networkManager;

  List<NodeEntity> _nodes = [];
  List<MessageEntity> _messages = [];
  MeshConnectivityState _connectivityState = MeshConnectivityState.connected;
  RoutingMetrics _metrics = RoutingMetrics();
  int _pendingQueueSize = 0;

  List<NodeEntity> get nodes => _nodes;
  List<MessageEntity> get messages => _messages;
  MeshConnectivityState get connectivityState => _connectivityState;
  RoutingMetrics get metrics => _metrics;
  int get pendingQueueSize => _pendingQueueSize;
  String get localNodeId => networkManager.identityService.myNodeId;
  String get displayName => networkManager.identityService.displayName;
  bool get isEmergencyMode => networkManager.isEmergencyMode;

  MeshStateProvider({required this.networkManager}) {
    _init();
  }

  void _init() {
    networkManager.nodeRepository.watchNodes().listen((n) {
      _nodes = n;
      notifyListeners();
    });

    networkManager.messageRepository.watchMessages().listen((m) {
      _messages = m;
      notifyListeners();
    });

    networkManager.connectivityStream.listen((state) {
      _connectivityState = state;
      notifyListeners();
    });

    networkManager.routingEngine.metricsStream.listen((met) {
      _metrics = met;
      notifyListeners();
    });

    networkManager.routingEngine.packetQueue.queueSizeStream.listen((size) {
      _pendingQueueSize = size;
      notifyListeners();
    });

    networkManager.startMeshNetwork();
  }

  Future<void> sendChatMessage(String receiverId, String text) async {
    await networkManager.sendChatMessage(receiverId: receiverId, text: text);
  }

  Future<void> sendEmergencyBroadcast({
    required EmergencyCategory category,
    required String title,
    required String description,
    bool includeLocation = false,
    double? lat,
    double? lng,
  }) async {
    await networkManager.sendEmergencyBroadcast(
      category: category,
      title: title,
      description: description,
      includeLocation: includeLocation,
      latitude: lat,
      longitude: lng,
    );
    notifyListeners();
  }

  Future<void> connectToNode(String nodeId) async {
    await networkManager.transport.connect(nodeId);
    await networkManager.nodeRepository.updateNodeStatus(nodeId, NodeConnectionStatus.connected);
  }

  Future<void> disconnectNode(String nodeId) async {
    await networkManager.transport.disconnect(nodeId);
    await networkManager.nodeRepository.updateNodeStatus(nodeId, NodeConnectionStatus.available);
  }
}
