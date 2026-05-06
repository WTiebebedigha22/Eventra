import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/chat/chat_message.dart';
import '../../services/imgbb_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImgBBService _imgbbService = ImgBBService();

  String get currentUid => _auth.currentUser?.uid ?? '';

  // ─────────────────────────────
  // ID GENERATION (CONSISTENT)
  // ─────────────────────────────

  /// Generates a consistent ID for a 1-to-1 chat.
  /// Always returns 'smallerUid_largerUid' regardless of who calls it.
  String getChatId(String otherUserId) {
    if (currentUid.isEmpty) return '';
    List<String> ids = [currentUid, otherUserId];
    ids.sort(); // Sorting ensures both users point to the same document
    return ids.join('_');
  }

  // ─────────────────────────────
  // CONVERSATIONS
  // ─────────────────────────────

  Stream<QuerySnapshot> getConversationsStream() {
    return _firestore
        .collection('chats') // Updated from chat_sessions
        .where('participants', arrayContains: currentUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Future<void> deleteConversation(String chatId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('chats').doc(chatId));
    await batch.commit();
  }

  // ─────────────────────────────
  // MESSAGES
  // ─────────────────────────────

  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    debugPrint(">> ChatService: Listening to chats/$chatId/messages");
    return _firestore
        .collection('chats') // Updated from chat_sessions
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(">> ChatService: Received ${snapshot.docs.length} docs from Firestore");
          return snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList();
        });
  }

  Future<void> sendMessage({
    required String chatId, 
    required String messageText,
    required String otherUserId,
    File? imageFile,
  }) async {
    if (currentUid.isEmpty) return;

    String imageUrl = '';

    // Upload image if present
    if (imageFile != null) {
      imageUrl = await ImgBBService.uploadImage(imageFile) ?? '';
    }

    // Don't send if both are empty
    if (messageText.trim().isEmpty && imageUrl.isEmpty) return;

    final String finalMessage =
        imageUrl.isNotEmpty && messageText.isEmpty ? '📷 Photo' : messageText;

    final now = FieldValue.serverTimestamp();

    // Update or Create the Chat Parent Doc
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [currentUid, otherUserId]..sort(),
      'lastMessage': finalMessage,
      'lastMessageSenderId': currentUid,
      'lastMessageTime': now,
      'unreadCounts.$otherUserId': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Add Message to Subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'chatId': chatId,
      'senderId': currentUid,
      'receiverId': otherUserId,
      'message': messageText.trim(),
      'imageUrl': imageUrl,
      'type': imageFile != null && messageText.isEmpty
          ? 'image'
          : imageFile != null
              ? 'image_text'
              : 'text',
      'createdAt': now,
      'isRead': false,
    });

    await setTypingStatus(otherUserId: otherUserId, isTyping: false);
  }

  // ─────────────────────────────
  // READ RECEIPTS
  // ─────────────────────────────

  Future<void> markAsRead(String chatId) async {
    if (currentUid.isEmpty) return;
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$currentUid': 0,
      });
    } catch (e) {
      debugPrint(">> Error marking as read: $e");
    }
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
    final msgDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return DateFormat.jm().format(dateTime);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat.E().format(dateTime);
    return DateFormat('MM/dd/yy').format(dateTime);
  }
}