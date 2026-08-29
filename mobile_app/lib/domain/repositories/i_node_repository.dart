import '../models/node_entity.dart';

abstract class INodeRepository {
  Future<List<NodeEntity>> getDiscoveredNodes();
  Future<NodeEntity?> getNode(String nodeId);
  Future<void> saveOrUpdateNode(NodeEntity node);
  Future<void> removeNode(String nodeId);
  Future<void> updateNodeStatus(String nodeId, NodeConnectionStatus status);
  Stream<List<NodeEntity>> watchNodes();
}
