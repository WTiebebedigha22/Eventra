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
    // Delete all messages first
    final messages = await _firestore
        .collection('chat_sessions')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete the session doc itself
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
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
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
      'senderId': currentUid,
      'receiverId': otherUserId,
      'text': messageText,
      'imageUrl': imageUrl,
      'timestamp': now,
    });

    // Clear typing status after sending
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
  // Writes `typingTo: otherUserId` on the current user's doc while typing,
  // clears it when done. ChatListScreen reads this to show the indicator.
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
  // Call on app foreground/background transitions.
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
  // Accepts nullable DateTime — Firestore serverTimestamp() is null
  // on the first local write before the server responds.
  // ─────────────────────────────

  String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) {
      // Today → show time e.g. "3:45 PM"
      return DateFormat.jm().format(dateTime);
    } else if (diff == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (diff < 7) {
      // This week → show day e.g. "Mon"
      return DateFormat.E().format(dateTime);
    } else {
      // Older → show date e.g. "04/12/25"
      return DateFormat('MM/dd/yy').format(dateTime);
    }
  }
}