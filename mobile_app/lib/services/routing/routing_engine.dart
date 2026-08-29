import 'dart:async';
import '../../domain/models/mesh_packet.dart';
import '../../domain/models/node_entity.dart';
import '../transport/mesh_transport.dart';
import 'deduplication_cache.dart';
import 'packet_queue.dart';

class RoutingMetrics {
  int packetsSent = 0;
  int packetsReceived = 0;
  int packetsRelayed = 0;
  int packetsDroppedDuplicates = 0;
  int packetsDroppedExpiredTtl = 0;
  int deliveryAcksReceived = 0;
}

class RoutingEngine {
  final String localNodeId;
  final MeshTransport transport;
  final DeduplicationCache dedupeCache = DeduplicationCache();
  final PacketQueue packetQueue = PacketQueue();
  final RoutingMetrics metrics = RoutingMetrics();

  final _deliveredPacketController = StreamController<MeshPacket>.broadcast();
  Stream<MeshPacket> get deliveredPackets => _deliveredPacketController.stream;

  final _ackController = StreamController<String>.broadcast();
  Stream<String> get ackStream => _ackController.stream;

  final _metricsController = StreamController<RoutingMetrics>.broadcast();
  Stream<RoutingMetrics> get metricsStream => _metricsController.stream;

  StreamSubscription? _incomingSub;

  RoutingEngine({
    required this.localNodeId,
    required this.transport,
  }) {
    _incomingSub = transport.incomingPackets.listen(_handleIncomingPacket);
  }

  /// Send a newly originated packet into the mesh
  Future<bool> routeNewPacket(MeshPacket packet) async {
    dedupeCache.isDuplicate(packet.packetId); // Mark local packet in cache
    metrics.packetsSent++;
    _metricsController.add(metrics);

    // Queue in store-and-forward buffer until confirmed
    if (packet.type == PacketType.chat) {
      packetQueue.enqueue(packet);
    }

    return await transport.sendPacket(packet);
  }

  /// Process an incoming packet from neighbor peer
  void _handleIncomingPacket(MeshPacket packet) {
    // 1. Loop prevention: Check duplicate cache
    if (dedupeCache.isDuplicate(packet.packetId)) {
      metrics.packetsDroppedDuplicates++;
      _metricsController.add(metrics);
      return;
    }

    metrics.packetsReceived++;
    _metricsController.add(metrics);

    // 2. Is this packet an ACK for our message?
    if (packet.type == PacketType.ack && packet.receiverId == localNodeId) {
      final originalPacketId = packet.packetId.replaceFirst('ack_', '');
      packetQueue.remove(originalPacketId);
      metrics.deliveryAcksReceived++;
      _ackController.add(originalPacketId);
      _metricsController.add(metrics);
      return;
    }

    // 3. Is this message destined for this local node or a broadcast?
    final isForMe = packet.receiverId == localNodeId || packet.isBroadcast;
    if (isForMe) {
      _deliveredPacketController.add(packet);

      // If targeted chat message, emit ACK back through the mesh
      if (packet.type == PacketType.chat && !packet.isBroadcast) {
        _sendAck(packet);
      }
    }

    // 4. Relay logic (if not solely for this node or if broadcast)
    if (!isForMe || packet.isBroadcast) {
      _relayPacket(packet);
    }
  }

  void _relayPacket(MeshPacket packet) {
    if (packet.isExpired) {
      metrics.packetsDroppedExpiredTtl++;
      _metricsController.add(metrics);
      return;
    }

    final canRelay = packet.relay(localNodeId);
    if (canRelay) {
      metrics.packetsRelayed++;
      _metricsController.add(metrics);
      transport.sendPacket(packet);
    }
  }

  void _sendAck(MeshPacket originalPacket) {
    final ackPacket = MeshPacket(
      packetId: 'ack_${originalPacket.packetId}',
      type: PacketType.ack,
      senderId: localNodeId,
      senderName: 'Node',
      receiverId: originalPacket.senderId,
      payload: 'ACK_DELIVERED',
      ttl: 10,
      hopCount: 1,
    );
    transport.sendPacket(ackPacket);
  }

  /// Sync stored pending queue when a new peer is discovered or reconnected
  void syncQueueWithPeer(NodeEntity peer) {
    final pending = packetQueue.getPacketsForReceiver(peer.nodeId);
    for (final packet in pending) {
      transport.sendPacket(packet, targetEndpointId: peer.nodeId);
    }
  }

  void dispose() {
    _incomingSub?.cancel();
    _deliveredPacketController.close();
    _ackController.close();
    _metricsController.close();
    packetQueue.dispose();
  }
}
