import 'dart:async';
import '../../domain/models/message_entity.dart';
import '../../domain/repositories/i_message_repository.dart';

class MessageRepositoryImpl implements IMessageRepository {
  final Map<String, MessageEntity> _messages = {};
  final _messagesStreamController = StreamController<List<MessageEntity>>.broadcast();

  MessageRepositoryImpl() {
    _initDemoMessages();
  }

  void _initDemoMessages() {
    // Seed initial broadcast welcome message
    final welcome = MessageEntity(
      messageId: 'msg_sys_welcome',
      conversationId: 'BROADCAST',
      senderId: 'SYSTEM',
      senderName: 'MeshLink Network',
      receiverId: '*',
      text: 'MeshLink emergency mesh network active. All messages are stored locally and relayed through nearby devices.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      status: MessageDeliveryStatus.delivered,
      hopCount: 1,
      isEmergency: false,
      isOutgoing: false,
    );
    _messages[welcome.messageId] = welcome;
    _notify();
  }

  void _notify() {
    _messagesStreamController.add(_messages.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
  }

  @override
  Future<List<MessageEntity>> getAllMessages() async {
    return _messages.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<List<MessageEntity>> getMessagesForConversation(String conversationId) async {
    return _messages.values
        .where((m) =>
            m.conversationId == conversationId ||
            (conversationId == 'BROADCAST' && m.isEmergency) ||
            m.receiverId == conversationId ||
            m.senderId == conversationId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<List<MessageEntity>> getPendingMessages() async {
    return _messages.values
        .where((m) =>
            m.status == MessageDeliveryStatus.storedLocally ||
            m.status == MessageDeliveryStatus.relaying)
        .toList();
  }

  @override
  Future<void> saveMessage(MessageEntity message) async {
    _messages[message.messageId] = message;
    _notify();
  }

  @override
  Future<void> updateMessageStatus(String messageId, MessageDeliveryStatus status, {int? hopCount}) async {
    final existing = _messages[messageId];
    if (existing != null) {
      _messages[messageId] = existing.copyWith(
        status: status,
        hopCount: hopCount ?? existing.hopCount,
      );
      _notify();
    }
  }

  @override
  Stream<List<MessageEntity>> watchMessages() => _messagesStreamController.stream;

  @override
  Stream<List<MessageEntity>> watchConversation(String conversationId) {
    return _messagesStreamController.stream.map((messages) => messages
        .where((m) =>
            m.conversationId == conversationId ||
            (conversationId == 'BROADCAST' && m.isEmergency) ||
            m.receiverId == conversationId ||
            m.senderId == conversationId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
  }

  void dispose() {
    _messagesStreamController.close();
  }
}
