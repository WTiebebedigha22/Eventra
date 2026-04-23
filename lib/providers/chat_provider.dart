import 'dart:io';
import 'package:flutter/foundation.dart';

import '../services/chat_service.dart';
import '../models/chat/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;

  ChatProvider(this._chatService);

  /// ─────────────────────────────
  /// LOAD CHAT STREAM
  /// ─────────────────────────────
  Stream<List<ChatMessage>> loadChat(String chatId) {
    _chatService.markAsRead(chatId);
    return _chatService.getMessagesStream(chatId);
  }

  /// ─────────────────────────────
  /// SEND MESSAGE (TEXT + IMAGE)
  /// ─────────────────────────────
  Future<void> send({
    required String chatId,
    required String messageText,
    required String otherUserId,
    File? imageFile,
  }) async {
    try {
      await _chatService.sendMessage(
        chatId: chatId,
        messageText: messageText,
        otherUserId: otherUserId,
        imageFile: imageFile,
      );
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }
}