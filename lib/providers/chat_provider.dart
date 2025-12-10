// lib/providers/chat_provider.dart

import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';
import '../models/chat/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  // 💡 Instantiate your finalized ChatService here
  final ChatService _chatService;

  // Constructor for dependency injection (good practice)
  ChatProvider(this._chatService);

  // --- 1. Load Messages Stream (Simplified) ---
  // Since ChatService is already type-safe, this method just delegates.
  Stream<List<ChatMessage>> loadChat(String chatId) {
    // 💡 Delegate directly to the type-safe stream from ChatService
    return _chatService.getMessagesStream(chatId); 
  }

  // --- 2. Send Message (Simplified) ---
  // The service handles building the full ChatMessage, setting senderId via FirebaseAuth,
  // and updating Firestore (messages subcollection and conversation doc).
  Future<void> send(String chatId, String messageText) async {
    // 💡 Only need to pass the chat ID and the text. 
    // The service fetches the senderId internally.
    await _chatService.sendMessage(chatId, messageText);
  }

  // --- Placeholder for Chat List Stream ---
  // You would also need a method to expose the stream for the ChatListScreen
  // Stream<List<Conversation>> get conversationsStream => _chatService.getConversationsStream();
}