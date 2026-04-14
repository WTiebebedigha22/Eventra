import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/chat/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- 1. Get List of Conversations (Inbox) ---
  Stream<QuerySnapshot> getConversationsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // --- 2. Get Messages for a Specific Chat (Bubbles) ---
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map<ChatMessage>((doc) {
        return ChatMessage.fromFirestore(doc);
      }).toList();
    });
  }

  // --- 3. Send Message & Update Metadata ---
  Future<void> sendMessage(String chatId, String text, String otherUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || text.trim().isEmpty) return;

    WriteBatch batch = _firestore.batch();
    DocumentReference msgRef = _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .doc();
    DocumentReference chatRef = _firestore.collection('conversations').doc(chatId);

    batch.set(msgRef, {
      'chatId': chatId,
      'senderId': uid,
      'message': text.trim(),
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts.$otherUserId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // --- 4. Get or Create Conversation ID ---
  Future<String> getOrCreateConversation(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("User not logged in");

    // Create unique ID by sorting UIDs
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatId = ids.join('_');

    final chatDoc = await _firestore.collection('conversations').doc(chatId).get();

    if (!chatDoc.exists) {
      await _firestore.collection('conversations').doc(chatId).set({
        'participants': ids,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {currentUserId: 0, otherUserId: 0},
      });
    }

    return chatId;
  }

  // --- 5. Mark Messages as Read ---
  Future<void> markAsRead(String chatId) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('conversations').doc(chatId).update({
        'unreadCounts.$uid': 0,
      });
    }
  }

  // --- 6. Helper: Fetch User Profiles ---
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  // --- 7. Helper: Format Dates ---
  String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}