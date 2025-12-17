import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat/chat_message.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _conversationCollection = 'conversations';

  // --- 1. Real-Time Conversations Stream (For Inbox) ---
  Stream<QuerySnapshot> getConversationsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection(_conversationCollection)
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // --- 2. NEW: Fetch Other User's Profile Info ---
  // This is used by the UI to turn a "UID" into a "Name" and "Photo"
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // --- 3. Get or Create Conversation (Optimized) ---
  Future<String> getOrCreateConversation(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("User not logged in");

    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatId = ids.join('_');

    final chatDoc = await _firestore.collection(_conversationCollection).doc(chatId).get();

    if (!chatDoc.exists) {
      await _firestore.collection(_conversationCollection).doc(chatId).set({
        'participants': ids,
        'lastMessage': 'Start a conversation!',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  // --- 4. Real-Time Message Stream ---
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection(_conversationCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // --- 5. Send Message (Using Batch for Consistency) ---
  Future<void> sendMessage(String chatId, String messageText) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || messageText.trim().isEmpty) return;

    try {
      final messageData = {
        'chatId': chatId,
        'senderId': currentUserId,
        'message': messageText.trim(),
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
      };

      WriteBatch batch = _firestore.batch();
      DocumentReference msgRef = _firestore.collection(_conversationCollection).doc(chatId).collection('messages').doc();
      DocumentReference chatRef = _firestore.collection(_conversationCollection).doc(chatId);

      batch.set(msgRef, messageData);
      batch.update(chatRef, {
        'lastMessage': messageText.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // --- 6. Formatter ---
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = (timestamp is Timestamp) ? timestamp.toDate() : (timestamp is DateTime ? timestamp : DateTime.now());
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}