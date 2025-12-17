import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final String type; // 'text', 'image', 'location'
  final DateTime createdAt;
  final bool isRead; // Added for standard inbox tracking

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'text',
      // Standard: Handle potential null or missing timestamps gracefully
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'message': message,
      'type': type,
      // Standard: Use serverTimestamp for the actual DB write to avoid phone clock issues
      'createdAt': FieldValue.serverTimestamp(), 
      'isRead': isRead,
    };
  }
}