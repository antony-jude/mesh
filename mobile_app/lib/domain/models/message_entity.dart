enum MessageDeliveryStatus {
  storedLocally, // ✓ Stored locally (Pending neighbor connection)
  relaying,      // ↗ Relaying across mesh hops
  delivered,     // ✓ Delivered to recipient node
  read,          // ✓✓ Read by recipient
}

class MessageEntity {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final MessageDeliveryStatus status;
  final int hopCount;
  final bool isEmergency;
  final bool isOutgoing;

  MessageEntity({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.status = MessageDeliveryStatus.storedLocally,
    this.hopCount = 0,
    this.isEmergency = false,
    this.isOutgoing = true,
  });

  MessageEntity copyWith({
    String? messageId,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    MessageDeliveryStatus? status,
    int? hopCount,
    bool? isEmergency,
    bool? isOutgoing,
  }) {
    return MessageEntity(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      hopCount: hopCount ?? this.hopCount,
      isEmergency: isEmergency ?? this.isEmergency,
      isOutgoing: isOutgoing ?? this.isOutgoing,
    );
  }

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'receiver_id': receiverId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'hop_count': hopCount,
        'is_emergency': isEmergency,
        'is_outgoing': isOutgoing,
      };

  factory MessageEntity.fromJson(Map<String, dynamic> json) => MessageEntity(
        messageId: json['message_id'] as String,
        conversationId: json['conversation_id'] as String? ?? json['receiver_id'] as String,
        senderId: json['sender_id'] as String,
        senderName: json['sender_name'] as String? ?? 'Node',
        receiverId: json['receiver_id'] as String,
        text: json['text'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now(),
        status: MessageDeliveryStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => MessageDeliveryStatus.storedLocally,
        ),
        hopCount: (json['hop_count'] as num?)?.toInt() ?? 0,
        isEmergency: json['is_emergency'] as bool? ?? false,
        isOutgoing: json['is_outgoing'] as bool? ?? false,
      );
}
