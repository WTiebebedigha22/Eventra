// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Import for @required and ChangeNotifier
import '../models/chat/chat_message.dart'; // Assuming the path to your model

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Firestore collection reference for all chats/conversations
  final String _conversationCollection = 'conversations';

  // --- Real-Time Message Stream ---
  // Streams a list of ChatMessage objects for a specific chat ID.
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    // 1. Get the stream of snapshots ordered by creation time
    final sub = _firestore
        .collection(_conversationCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true) // Newest at the top of the stream
        .snapshots();
        
    // 2. Map the QuerySnapshot to a List<ChatMessage>
    return sub.map((snapshot) {
      return snapshot.docs.map((doc) {
        // Use the factory constructor from the ChatMessage model
        return ChatMessage.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- Send Message Function ---
  Future<void> sendMessage(String chatId, String messageText) async {
    final currentUserId = _auth.currentUser?.uid;
    
    if (currentUserId == null || messageText.trim().isEmpty) {
      // Throw an error or log if the user isn't authenticated or message is empty
      throw Exception("User not authenticated or message is empty.");
    }
    
    try {
      // 1. Prepare the ChatMessage model instance
      final newMessage = ChatMessage(
        id: '', // Firestore will assign the ID
        chatId: chatId,
        senderId: currentUserId,
        message: messageText.trim(),
        type: 'text',
        createdAt: DateTime.now(),
      );
      
      final messageData = newMessage.toMap();
      
      // 2. Add the message to the 'messages' subcollection
      await _firestore
          .collection(_conversationCollection)
          .doc(chatId)
          .collection('messages')
          .add(messageData);
          
      // 3. Update the parent conversation document for last message info
      await _firestore.collection(_conversationCollection).doc(chatId).update({
        'lastMessage': messageText.trim(),
        'lastMessageTime': messageData['createdAt'], // Use the Timestamp
      });
      
    } catch (e) {
      debugPrint('Error sending message to chat $chatId: $e');
      rethrow; // Re-throw the error for the UI layer to handle
    }
  }

  // NOTE: You would also have methods here for:
  // - getConversationsStream() (for the ChatListScreen)
  // - getOrCreateConversation(String otherUserId)
}