import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../models/chat/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser?.uid ?? '';

  // ─────────────────────────────
  // CONVERSATIONS
  // ─────────────────────────────

  Stream<QuerySnapshot> getConversationsStream() {
    return _firestore
        .collection('chat_sessions')
        .where('participants', arrayContains: currentUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Deletes the session doc AND all its messages in a batched write.
  Future<void> deleteConversation(String chatId) async {
    final messages = await _firestore
        .collection('chat_sessions')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('chat_sessions').doc(chatId));
    await batch.commit();
  }

  // ─────────────────────────────
  // MESSAGES
  // ─────────────────────────────

  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chat_sessions')
        .doc(chatId)
        .collection('messages')
        // ✅ FIX: order by 'createdAt' — matches ChatMessage.fromMap
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String messageText,
    required String otherUserId,
    File? imageFile,
  }) async {
    String imageUrl = '';

    if (imageFile != null) {
      final ref = _storage
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final String finalMessage =
        imageUrl.isNotEmpty && messageText.isEmpty ? '📷 Photo' : messageText;

    final now = FieldValue.serverTimestamp();

    await _firestore.collection('chat_sessions').doc(chatId).set({
      'participants': [currentUid, otherUserId]..sort(),
      'lastMessage': finalMessage,
      'lastMessageSenderId': currentUid,
      'lastMessageTime': now,
      'unreadCounts.$otherUserId': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await _firestore
        .collection('chat_sessions')
        .doc(chatId)
        .collection('messages')
        .add({
      'chatId': chatId,
      'senderId': currentUid,
      'receiverId': otherUserId,
      // ✅ FIX: was 'text', must be 'message' to match ChatMessage.fromMap
      'message': messageText,
      'imageUrl': imageUrl,
      'type': imageFile != null && messageText.isEmpty
          ? 'image'
          : imageFile != null
              ? 'image_text'
              : 'text',
      // ✅ FIX: was 'timestamp', must be 'createdAt' to match ChatMessage.fromMap
      'createdAt': now,
      'isRead': false,
    });

    await setTypingStatus(otherUserId: otherUserId, isTyping: false);
  }

  // ─────────────────────────────
  // READ RECEIPTS
  // ─────────────────────────────

  Future<void> markAsRead(String chatId) async {
    await _firestore.collection('chat_sessions').doc(chatId).update({
      'unreadCounts.$currentUid': 0,
    });
  }

  // ─────────────────────────────
  // TYPING STATUS
  // ─────────────────────────────

  Future<void> setTypingStatus({
    required String otherUserId,
    required bool isTyping,
  }) async {
    if (currentUid.isEmpty) return;
    await _firestore.collection('users').doc(currentUid).update({
      'typingTo': isTyping ? otherUserId : null,
    });
  }

  // ─────────────────────────────
  // ONLINE PRESENCE
  // ─────────────────────────────

  Future<void> setOnlineStatus(bool isOnline) async {
    if (currentUid.isEmpty) return;
    await _firestore.collection('users').doc(currentUid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────
  // USER PROFILE
  // ─────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // ─────────────────────────────
  // TIMESTAMP FORMATTING
  // ─────────────────────────────

  String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay =
        DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return DateFormat.jm().format(dateTime);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat.E().format(dateTime);
    return DateFormat('MM/dd/yy').format(dateTime);
  }
}