import 'dart:async';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/crypto_utils.dart';
import '../domain/models/emergency_payload.dart';
import '../domain/models/message_entity.dart';
import '../domain/models/mesh_packet.dart';
import '../domain/models/node_entity.dart';
import '../domain/repositories/i_message_repository.dart';
import '../domain/repositories/i_node_repository.dart';
import 'routing/routing_engine.dart';
import 'security/identity_service.dart';
import 'transport/mesh_transport.dart';
import 'transport/simulated_transport.dart';

enum MeshConnectivityState {
  connected, // 🟢 Connected to mesh (>= 2 peers)
  limited,   // 🟡 Limited mesh (1 peer)
  isolated,  // 🔴 Isolated / No nearby nodes
}

class MeshNetworkManager {
  final IdentityService identityService;
  final IMessageRepository messageRepository;
  final INodeRepository nodeRepository;
  final MeshTransport transport;
  late final RoutingEngine routingEngine;


  MeshConnectivityState _connectivityState = MeshConnectivityState.connected;
  MeshConnectivityState get connectivityState => _connectivityState;

  bool _isEmergencyMode = false;
  bool get isEmergencyMode => _isEmergencyMode;
  bool _isMeshStarted = false;
  bool _isStartingMesh = false;

  final _stateController = StreamController<MeshConnectivityState>.broadcast();
  Stream<MeshConnectivityState> get connectivityStream => _stateController.stream;

  StreamSubscription? _deliveredSub;
  StreamSubscription? _ackSub;
  StreamSubscription? _nodesSub;

  MeshNetworkManager({
    required this.identityService,
    required this.messageRepository,
    required this.nodeRepository,
    required this.transport,
  }) {
    routingEngine = RoutingEngine(
      localNodeId: identityService.myNodeId,
      transport: transport,
    );

    _initListeners();
  }

  void _initListeners() {
    // 1. Listen for delivered packets from mesh
    _deliveredSub = routingEngine.deliveredPackets.listen(_onPacketDelivered);

    // 2. Listen for delivery ACKs
    _ackSub = routingEngine.ackStream.listen((packetId) {
      messageRepository.updateMessageStatus(packetId, MessageDeliveryStatus.delivered);
    });

    // 3. Listen for discovered nodes to update connectivity state
    _nodesSub = nodeRepository.watchNodes().listen((nodes) {
      final activeNodes = nodes.where((n) => n.status == NodeConnectionStatus.connected).length;
      if (activeNodes >= 2) {
        _connectivityState = MeshConnectivityState.connected;
      } else if (activeNodes == 1) {
        _connectivityState = MeshConnectivityState.limited;
      } else {
        _connectivityState = MeshConnectivityState.isolated;
      }
      _stateController.add(_connectivityState);
    });
  }

  Future<void> startMeshNetwork() async {
    // Mesh is already running
    if (_isMeshStarted) {
      return;
    }

    // Prevent multiple startup calls at the same time
    if (_isStartingMesh) {
      return;
    }

    _isStartingMesh = true;

    try {
      await transport.initialize(
        identityService.myNodeId,
        identityService.displayName,
      );

      await transport.startAdvertising();
      await transport.startDiscovery();

      _isMeshStarted = true;
    } catch (e) {
      // Allow another attempt if startup fails
      _isMeshStarted = false;
      rethrow;
    } finally {
      _isStartingMesh = false;
    }
  }

  /// Send a 1-to-1 or group chat message
  Future<void> sendChatMessage({
    required String receiverId,
    required String text,
    String? conversationId,
  }) async {
    final messageId = 'msg_${const Uuid().v4().substring(0, 8)}';
    final encryptedText = CryptoUtils.encryptPayload(text);

    final packet = MeshPacket(
      packetId: messageId,
      type: PacketType.chat,
      senderId: identityService.myNodeId,
      senderName: identityService.displayName,
      receiverId: receiverId,
      payload: encryptedText,
      ttl: AppConstants.defaultTtl,
      hopCount: 0,
    );

    final message = MessageEntity(
      messageId: messageId,
      conversationId: conversationId ?? receiverId,
      senderId: identityService.myNodeId,
      senderName: identityService.displayName,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
      status: MessageDeliveryStatus.relaying,
      hopCount: 0,
      isEmergency: false,
      isOutgoing: true,
    );

    await messageRepository.saveMessage(message);
    await routingEngine.routeNewPacket(packet);
  }

  /// Send an Emergency Broadcast
  Future<void> sendEmergencyBroadcast({
    required EmergencyCategory category,
    required String title,
    required String description,
    bool includeLocation = false,
    double? latitude,
    double? longitude,
  }) async {
    final messageId = 'emg_${const Uuid().v4().substring(0, 8)}';
    final payload = EmergencyPayload(
      category: category,
      title: title,
      description: description,
      hasLocation: includeLocation,
      latitude: latitude,
      longitude: longitude,
    );

    final packet = MeshPacket(
      packetId: messageId,
      type: PacketType.emergency,
      senderId: identityService.myNodeId,
      senderName: identityService.displayName,
      receiverId: '*',
      payload: payload.serialize(),
      ttl: AppConstants.emergencyTtl,
      hopCount: 0,
    );

    final message = MessageEntity(
      messageId: messageId,
      conversationId: 'BROADCAST',
      senderId: identityService.myNodeId,
      senderName: identityService.displayName,
      receiverId: '*',
      text: '[EMERGENCY - ${category.name.toUpperCase()}]: $title\n$description',
      timestamp: DateTime.now(),
      status: MessageDeliveryStatus.delivered,
      hopCount: 0,
      isEmergency: true,
      isOutgoing: true,
    );

    _isEmergencyMode = true;
    await messageRepository.saveMessage(message);
    await routingEngine.routeNewPacket(packet);
  }

  void _onPacketDelivered(MeshPacket packet) async {
    if (packet.type == PacketType.chat) {
      final decryptedText = CryptoUtils.decryptPayload(packet.payload);
      final message = MessageEntity(
        messageId: packet.packetId,
        conversationId: packet.senderId,
        senderId: packet.senderId,
        senderName: packet.senderName,
        receiverId: packet.receiverId,
        text: decryptedText,
        timestamp: packet.timestamp,
        status: MessageDeliveryStatus.delivered,
        hopCount: packet.hopCount,
        isEmergency: false,
        isOutgoing: false,
      );
      await messageRepository.saveMessage(message);
    } else if (packet.type == PacketType.emergency) {
      try {
        final emg = EmergencyPayload.deserialize(packet.payload);
        final message = MessageEntity(
          messageId: packet.packetId,
          conversationId: 'BROADCAST',
          senderId: packet.senderId,
          senderName: packet.senderName,
          receiverId: '*',
          text: '[EMERGENCY - ${emg.category.name.toUpperCase()}]: ${emg.title}\n${emg.description}',
          timestamp: packet.timestamp,
          status: MessageDeliveryStatus.delivered,
          hopCount: packet.hopCount,
          isEmergency: true,
          isOutgoing: false,
        );
        await messageRepository.saveMessage(message);
      } catch (_) {}
    }
  }

  void dispose() {
    _deliveredSub?.cancel();
    _ackSub?.cancel();
    _nodesSub?.cancel();

    _isMeshStarted = false;
    _isStartingMesh = false;

    _stateController.close();

    routingEngine.dispose();
    transport.dispose();
  }
}
