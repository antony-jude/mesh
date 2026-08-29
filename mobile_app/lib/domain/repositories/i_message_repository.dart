import '../models/message_entity.dart';

abstract class IMessageRepository {
  Future<List<MessageEntity>> getMessagesForConversation(String conversationId);
  Future<List<MessageEntity>> getAllMessages();
  Future<List<MessageEntity>> getPendingMessages();
  Future<void> saveMessage(MessageEntity message);
  Future<void> updateMessageStatus(String messageId, MessageDeliveryStatus status, {int? hopCount});
  Stream<List<MessageEntity>> watchMessages();
  Stream<List<MessageEntity>> watchConversation(String conversationId);
}
