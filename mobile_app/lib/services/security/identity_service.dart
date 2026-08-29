import 'dart:math';
import 'package:uuid/uuid.dart';

class IdentityService {
  late final String myNodeId;
  late String displayName;

  IdentityService() {
    _initIdentity();
  }

  void _initIdentity() {
    // Generate deterministic anonymous short node identifier
    final randomHex = const Uuid().v4().substring(0, 4).toUpperCase();
    myNodeId = 'NODE-$randomHex';
    displayName = 'Mesh Responder ($randomHex)';
  }

  void updateDisplayName(String name) {
    displayName = name;
  }
}
