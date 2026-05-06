import 'dart:io';
import 'package:flutter/foundation.dart';

import '../services/chat_service.dart';
import '../models/chat/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;

  ChatProvider(this._chatService);

  // ─────────────────────────────
  // STATE MANAGEMENT
  // ─────────────────────────────
  bool _isSending = false;
  bool get isSending => _isSending;

  void _setSending(bool value) {
    _isSending = value;
    notifyListeners();
  }

  /// ─────────────────────────────
  /// LOAD CHAT STREAM
  /// ─────────────────────────────
  /// Returns a stream of messages for a specific chat.
  /// Ideally, your ChatService handles ordering (e.g., .orderBy('timestamp'))
  Stream<List<ChatMessage>> loadChat(String chatId) {
    debugPrint(">> ChatProvider: Loading stream for chatId: $chatId");
    return _chatService.getMessagesStream(chatId);
  }

  /// ─────────────────────────────
  /// MARK AS READ
  /// ─────────────────────────────
  /// Updates the 'unreadCount' or 'seen' status in Firestore.
  Future<void> markAsRead(String chatId) async {
    try {
      debugPrint(">> ChatProvider: Marking chatId $chatId as read");
      await _chatService.markAsRead(chatId);
      // We don't necessarily need notifyListeners here because the
      // message stream or conversation list stream will reflect the change.
    } catch (e) {
      debugPrint(">> ChatProvider: Error marking as read: $e");
    }
  }

  /// ─────────────────────────────
  /// SEND MESSAGE (TEXT + IMAGE)
  /// ─────────────────────────────
  Future<bool> send({
    required String chatId,
    required String messageText,
    required String otherUserId,
    File? imageFile,
  }) async {
    // Prevent empty sends if no image is present
    if (messageText.trim().isEmpty && imageFile == null) return false;

    try {
      _setSending(true);
      debugPrint(">> send() called — chatId: $chatId, text: $messageText");
      
      await _chatService.sendMessage(
        chatId: chatId,
        messageText: messageText,
        otherUserId: otherUserId,
        imageFile: imageFile,
      );
      
      debugPrint(">> send() SUCCESS ✅");
      return true;
    } catch (e, stack) {
      debugPrint(">> send() ERROR ❌: $e");
      debugPrint("$stack");
      return false;
    } finally {
      _setSending(false);
    }
  }
}