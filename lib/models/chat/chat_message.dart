import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final String imageUrl;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.imageUrl,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      // ✅ handles both old 'text' field and new 'message' field
      message: data['message'] ?? data['text'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? 'text',
      // ✅ handles both old 'timestamp' field and new 'createdAt' field
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  static ChatMessage fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'message': message,
      'imageUrl': imageUrl,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}