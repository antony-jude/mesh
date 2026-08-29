import 'dart:async';
import '../../domain/models/mesh_packet.dart';

class QueuedPacketItem {
  final MeshPacket packet;
  final DateTime queuedAt;
  int retryAttempts;

  QueuedPacketItem({
    required this.packet,
    DateTime? queuedAt,
    this.retryAttempts = 0,
  }) : queuedAt = queuedAt ?? DateTime.now();
}

class PacketQueue {
  final List<QueuedPacketItem> _pendingQueue = [];
  final _queueSizeController = StreamController<int>.broadcast();

  Stream<int> get queueSizeStream => _queueSizeController.stream;
  int get pendingCount => _pendingQueue.length;
  List<MeshPacket> get pendingPackets => _pendingQueue.map((item) => item.packet).toList();

  void enqueue(MeshPacket packet) {
    if (!_pendingQueue.any((item) => item.packet.packetId == packet.packetId)) {
      _pendingQueue.add(QueuedPacketItem(packet: packet));
      _queueSizeController.add(_pendingQueue.length);
    }
  }

  void remove(String packetId) {
    _pendingQueue.removeWhere((item) => item.packet.packetId == packetId);
    _queueSizeController.add(_pendingQueue.length);
  }

  List<MeshPacket> getPacketsForReceiver(String receiverId) {
    return _pendingQueue
        .where((item) => item.packet.receiverId == receiverId || item.packet.isBroadcast)
        .map((item) => item.packet)
        .toList();
  }

  void clear() {
    _pendingQueue.clear();
    _queueSizeController.add(0);
  }

  void dispose() {
    _queueSizeController.close();
  }
}
