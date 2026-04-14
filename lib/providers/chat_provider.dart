import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';
import '../models/chat/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;

  ChatProvider(this._chatService);

  Stream<List<ChatMessage>> loadChat(String chatId) {
    _chatService.markAsRead(chatId);
    return _chatService.getMessagesStream(chatId);
  }

  Future<void> send({
    required String chatId,
    required String messageText,
    required String otherUserId,
  }) async {
    try {
      await _chatService.sendMessage(chatId, messageText, otherUserId);
    } catch (e) {
      debugPrint("Error sending: $e");
    }
  }
}