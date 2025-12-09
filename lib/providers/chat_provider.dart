import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chat = ChatService();

  Stream<List<ChatMessage>> loadChat(String chatId) {
    return _chat.messagesStream(chatId).map((list) => list.map((m) => ChatMessage.fromMap(m, m['id'])).toList());
  }

  Future<void> send(String chatId, String text, String senderId) async {
    await _chat.sendMessage(chatId, {
      'message': text,
      'senderId': senderId,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'text',
      'chatId': chatId,
    });
  }
}
