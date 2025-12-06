import 'package:flutter/material.dart';
import '../models/chat/chat_message.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chat = ChatService();

  List<ChatMessage> messages = [];
  bool isLoading = false;

  Stream<List<ChatMessage>> loadChat(String chatId) {
    return _chat.getMessages(chatId);
  }

  Future<void> sendMessage(ChatMessage msg) async {
    await _chat.sendMessage(msg);
    notifyListeners();
  }
}
