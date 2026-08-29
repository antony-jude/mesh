import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/sos_packet.dart';

class MeshLogEntry {
  final DateTime timestamp;
  final String level; // INFO, WARN, PACKET, RELAY, SYNC
  final String message;
  final String? packetId;

  MeshLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.packetId,
  });
}

class MeshService {
  static const MethodChannel _channel = MethodChannel('com.resqmesh.app/nearby_mesh');

  final String deviceId;
  DeviceRole currentRole;

  // Track discovered and connected endpoints
  final Set<String> _connectedEndpoints = {};
  final Set<String> _seenPacketIds = {};
  final List<SosPacket> _receivedPackets = [];
  final List<SosPacket> _queuedForSync = [];
  final List<MeshLogEntry> _debugLogs = [];

  int _packetsReceivedCount = 0;
  int _packetsRelayedCount = 0;

  int get packetsReceivedCount => _packetsReceivedCount;
  int get packetsRelayedCount => _packetsRelayedCount;
  Set<String> get connectedEndpoints => _connectedEndpoints;
  List<SosPacket> get receivedPackets => List.unmodifiable(_receivedPackets);
  List<SosPacket> get queuedForSync => List.unmodifiable(_queuedForSync);
  List<MeshLogEntry> get debugLogs => List.unmodifiable(_debugLogs);

  final _packetStreamController = StreamController<SosPacket>.broadcast();
  Stream<SosPacket> get packetStream => _packetStreamController.stream;

  final _logStreamController = StreamController<MeshLogEntry>.broadcast();
  Stream<MeshLogEntry> get logStream => _logStreamController.stream;

  final _stateStreamController = StreamController<void>.broadcast();
  Stream<void> get stateStream => _stateStreamController.stream;

  MeshService({
    required this.deviceId,
    this.currentRole = DeviceRole.VICTIM,
  }) {
    _initMethodChannelHandler();
  }

  void _initMethodChannelHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onEndpointDiscovered':
          final endpointId = call.arguments['endpointId'] as String;
          final endpointName = call.arguments['endpointName'] as String;
          log('INFO', 'Discovered peer: $endpointName ($endpointId)');
          break;

        case 'onEndpointConnected':
          final endpointId = call.arguments['endpointId'] as String;
          _connectedEndpoints.add(endpointId);
          log('INFO', 'Connected to peer endpoint: $endpointId');
          _stateStreamController.add(null);
          break;

        case 'onEndpointDisconnected':
          final endpointId = call.arguments['endpointId'] as String;
          _connectedEndpoints.remove(endpointId);
          log('WARN', 'Disconnected from peer: $endpointId');
          _stateStreamController.add(null);
          break;

        case 'onPayloadReceived':
          final rawPayload = call.arguments['payload'] as String;
          final senderEndpointId = call.arguments['senderEndpointId'] as String?;
          _handleIncomingPayload(rawPayload, senderEndpointId: senderEndpointId);
          break;
      }
    });
  }

  void setRole(DeviceRole newRole) {
    currentRole = newRole;
    log('INFO', 'Role updated to: ${newRole.name}');
    _stateStreamController.add(null);
  }

  /// Start Nearby Connections P2P_CLUSTER Mesh Advertising and Discovery
  Future<void> startMesh() async {
    log('INFO', 'Starting P2P_CLUSTER Mesh Service as ${currentRole.name} (Device: $deviceId)');
    try {
      await _channel.invokeMethod('startMesh', {
        'deviceId': deviceId,
        'role': currentRole.name,
        'strategy': 'P2P_CLUSTER',
      });
      log('INFO', 'Google Nearby Connections P2P_CLUSTER active');
    } on PlatformException catch (e) {
      log('WARN', 'Native Nearby start error (using offline emulation bridge): ${e.message}');
    }
  }

  /// Stop Nearby Connections Mesh
  Future<void> stopMesh() async {
    try {
      await _channel.invokeMethod('stopMesh');
    } catch (_) {}
    _connectedEndpoints.clear();
    log('INFO', 'Mesh service stopped.');
    _stateStreamController.add(null);
  }

  /// Send newly originated SOS packet into the mesh
  Future<void> broadcastSosPacket(SosPacket packet) async {
    _seenPacketIds.add(packet.packetId);
    _receivedPackets.insert(0, packet);
    _packetsReceivedCount++;

    final encryptedPayload = packet.exportEncryptedPacket();
    log('PACKET', 'Originated SOS ${packet.packetId.substring(0, 8)} [${packet.priorityLabel.name}] | Lat:${packet.lastKnownLocation.lat}, Lng:${packet.lastKnownLocation.lng}', packetId: packet.packetId);

    // Transmit to all connected peers
    await _sendPayloadToPeers(encryptedPayload, excludeEndpoint: null);
    _packetStreamController.add(packet);
    _stateStreamController.add(null);
  }

  /// Handle incoming packet from another peer in the mesh
  void _handleIncomingPayload(String rawPayload, {String? senderEndpointId}) {
    try {
      final packet = SosPacket.fromEncryptedPayload(rawPayload);

      // Packet Deduplication: Ignore if already processed
      if (_seenPacketIds.contains(packet.packetId)) {
        log('INFO', 'Duplicate packet ${packet.packetId.substring(0, 8)} ignored (loop prevention)', packetId: packet.packetId);
        return;
      }

      _seenPacketIds.add(packet.packetId);
      _packetsReceivedCount++;
      _receivedPackets.insert(0, packet);

      log('PACKET', 'Received packet ${packet.packetId.substring(0, 8)} | Hops: ${packet.hopCount} | Path: ${packet.hopPath.join(" -> ")}', packetId: packet.packetId);

      // Role-specific forwarding behavior
      if (currentRole == DeviceRole.RELAY) {
        // Increment hop count & append own device ID
        packet.incrementHop(deviceId);
        _packetsRelayedCount++;

        log('RELAY', 'Relaying packet ${packet.packetId.substring(0, 8)} (Hop ${packet.hopCount}) across mesh', packetId: packet.packetId);

        // Flood-relay re-broadcast to all other peers
        final updatedPayload = packet.exportEncryptedPacket();
        _sendPayloadToPeers(updatedPayload, excludeEndpoint: senderEndpointId);
      } else if (currentRole == DeviceRole.GATEWAY) {
        // Queue for cloud sync
        _queuedForSync.add(packet);
        log('SYNC', 'Gateway queued packet ${packet.packetId.substring(0, 8)} for Firestore upload', packetId: packet.packetId);
      }

      _packetStreamController.add(packet);
      _stateStreamController.add(null);
    } catch (e) {
      log('WARN', 'Failed to decode incoming mesh payload: $e');
    }
  }

  /// Broadcast payload to connected endpoints via native channel or simulation
  Future<void> _sendPayloadToPeers(String payloadString, {String? excludeEndpoint}) async {
    try {
      await _channel.invokeMethod('sendPayload', {
        'payload': payloadString,
        'excludeEndpoint': excludeEndpoint,
      });
    } on PlatformException catch (_) {
      // In standalone simulation / web testbed mode
    }
  }

  /// Simulated peer transmission (for 3-phone testbed / debug harness)
  void simulateReceivePacket(SosPacket packet, {String? fromEndpoint}) {
    final payload = packet.exportEncryptedPacket();
    _handleIncomingPayload(payload, senderEndpointId: fromEndpoint);
  }

  /// Drain queued packets after successful sync
  void markPacketsSynced(List<String> packetIds) {
    _queuedForSync.removeWhere((p) => packetIds.contains(p.packetId));
    log('SYNC', 'Flushed ${packetIds.length} packets to Firestore cloud backend');
    _stateStreamController.add(null);
  }

  void log(String level, String message, {String? packetId}) {
    final entry = MeshLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      packetId: packetId,
    );
    _debugLogs.insert(0, entry);
    if (_debugLogs.length > 200) {
      _debugLogs.removeLast();
    }
    _logStreamController.add(entry);
  }

  void dispose() {
    stopMesh();
    _packetStreamController.close();
    _logStreamController.close();
    _stateStreamController.close();
  }
}
