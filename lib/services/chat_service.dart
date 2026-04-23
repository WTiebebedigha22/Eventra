import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/chat/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─────────────────────────────
  // 1. GET CONVERSATIONS
  // ─────────────────────────────
  Stream<QuerySnapshot> getConversationsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // ─────────────────────────────
  // 2. GET MESSAGES
  // ─────────────────────────────
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  // ─────────────────────────────
  // 3. SEND MESSAGE (TEXT + IMAGE)
  // ─────────────────────────────
  Future<void> sendMessage({
    required String chatId,
    required String messageText,
    required String otherUserId,
    File? imageFile,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    String imageUrl = '';

    // ── Upload image ──
    if (imageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_media')
          .child('$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final msgRef = _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('messages')
        .doc();

    final chatRef =
        _firestore.collection('conversations').doc(chatId);

    await _firestore.runTransaction((txn) async {
      // ── message ──
      txn.set(msgRef, {
        'chatId': chatId,
        'senderId': uid,
        'receiverId': otherUserId,
        'message': messageText.trim(),
        'imageUrl': imageUrl,
        'type': imageFile != null ? 'image' : 'text',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // ── conversation update ──
      txn.set(chatRef, {
        'participants': [uid, otherUserId],
        'lastMessage': imageFile != null ? '📷 Image' : messageText.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {
          otherUserId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));
    });
  }

  // ─────────────────────────────
  // 4. GET OR CREATE CHAT
  // ─────────────────────────────
  Future<String> getOrCreateConversation(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("Not logged in");

    final ids = [currentUserId, otherUserId]..sort();
    final chatId = ids.join('_');

    final doc =
        await _firestore.collection('conversations').doc(chatId).get();

    if (!doc.exists) {
      await _firestore.collection('conversations').doc(chatId).set({
        'participants': ids,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {
          currentUserId: 0,
          otherUserId: 0,
        },
      });
    }

    return chatId;
  }

  // ─────────────────────────────
  // 5. MARK AS READ
  // ─────────────────────────────
  Future<void> markAsRead(String chatId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('conversations')
        .doc(chatId)
        .update({'unreadCounts.$uid': 0});
  }

  // ─────────────────────────────
  // 6. FORMAT TIME
  // ─────────────────────────────
  String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  // ─────────────────────────────
  // 7. GET USER PROFILE
  // ─────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }
}