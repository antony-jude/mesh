import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/sos_packet.dart';
import 'mesh_service.dart';

class SyncService {
  final MeshService meshService;
  final String firestoreEndpoint;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicSyncTimer;

  final _syncEventController = StreamController<String>.broadcast();
  Stream<String> get syncEventStream => _syncEventController.stream;

  SyncService({
    required this.meshService,
    this.firestoreEndpoint = 'https://firestore.googleapis.com/v1/projects/resq-mesh-demo/databases/(default)/documents/sos_packets',
  });

  void startMonitoring() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none && r != ConnectivityResult.other);
      _handleConnectivityChange(hasConnection);
    });

    // Check initial state
    Connectivity().checkConnectivity().then((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      _handleConnectivityChange(hasConnection);
    });

    // Periodic flush timer when online
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isOnline && meshService.currentRole == DeviceRole.GATEWAY) {
        flushQueueToCloud();
      }
    });
  }

  void _handleConnectivityChange(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      meshService.log(
        online ? 'SYNC' : 'WARN',
        online ? 'Internet connection detected! Gateway online.' : 'Device offline (Airplane / Mesh-only mode).',
      );
      _syncEventController.add(online ? 'ONLINE' : 'OFFLINE');

      if (online && meshService.currentRole == DeviceRole.GATEWAY) {
        flushQueueToCloud();
      }
    }
  }

  /// Manually force or simulate connection state toggle (for airplane mode demo)
  void setSimulatedConnectivity(bool online) {
    _handleConnectivityChange(online);
  }

  /// Push all queued packets to Firestore in a batch write
  Future<int> flushQueueToCloud() async {
    final queue = meshService.queuedForSync;
    if (queue.isEmpty) return 0;

    final batchToSync = List<SosPacket>.from(queue);
    meshService.log('SYNC', 'Initiating batch upload of ${batchToSync.length} packets to Firestore...');

    try {
      // Simulated Firestore Batch Write latency
      await Future.delayed(const Duration(milliseconds: 600));

      final syncedIds = batchToSync.map((p) => p.packetId).toList();
      meshService.markPacketsSynced(syncedIds);
      _syncEventController.add('SYNCED_${syncedIds.length}');
      return syncedIds.length;
    } catch (e) {
      meshService.log('WARN', 'Firestore sync failed: $e');
      return 0;
    }
  }

  void stopMonitoring() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  void dispose() {
    stopMonitoring();
    _syncEventController.close();
  }
}
