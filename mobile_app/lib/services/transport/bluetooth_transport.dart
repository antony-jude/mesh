import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/models/mesh_packet.dart';
import '../../domain/models/node_entity.dart';
import 'mesh_transport.dart';

class BluetoothTransport implements MeshTransport {
  static const MethodChannel _channel = MethodChannel('com.meshlink.app/ble_transport');

  @override
  String get transportName => 'Bluetooth Low Energy (BLE Mesh)';

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

  @override
  Future<void> initialize(String localNodeId, String localDisplayName) async {
    _localNodeId = localNodeId;
    _localDisplayName = localDisplayName;
  }

  @override
  Future<void> startDiscovery() async {
    _isRunning = true;
    try {
      await _channel.invokeMethod('startBleScan');
    } catch (_) {}
  }

  @override
  Future<void> stopDiscovery() async {
    _isRunning = false;
    try {
      await _channel.invokeMethod('stopBleScan');
    } catch (_) {}
  }

  @override
  Future<void> startAdvertising() async {
    try {
      await _channel.invokeMethod('startBleAdvertise', {
        'nodeId': _localNodeId,
        'displayName': _localDisplayName,
      });
    } catch (_) {}
  }

  @override
  Future<void> stopAdvertising() async {
    try {
      await _channel.invokeMethod('stopBleAdvertise');
    } catch (_) {}
  }

  @override
  Future<bool> connect(String nodeId) async {
    try {
      final success = await _channel.invokeMethod<bool>('connectToDevice', {'nodeId': nodeId});
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> disconnect(String nodeId) async {
    try {
      await _channel.invokeMethod('disconnectDevice', {'nodeId': nodeId});
    } catch (_) {}
  }

  @override
  Future<bool> sendPacket(MeshPacket packet, {String? targetEndpointId}) async {
    try {
      final raw = packet.serialize();
      await _channel.invokeMethod('sendBleData', {
        'data': raw,
        'targetEndpointId': targetEndpointId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    stopDiscovery();
    stopAdvertising();
    _incomingPacketsController.close();
    _discoveredNodesController.close();
    _peerDisconnectedController.close();
  }
}
