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
  // GET CONVERSATIONS
  // ─────────────────────────────
  Stream<QuerySnapshot> getConversationsStream() {
    return _firestore
        .collection('chat_sessions')
        .where('participants', arrayContains: currentUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // ─────────────────────────────
  // GET MESSAGES STREAM (FOR PROVIDER)
  // ─────────────────────────────
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chat_sessions')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // ─────────────────────────────
  // SEND MESSAGE (Updated to match ChatProvider)
  // ─────────────────────────────
  Future<void> sendMessage({
    required String chatId, // Changed from sessionId to chatId
    required String messageText, // Changed from message to messageText
    required String otherUserId, // Changed from receiverId to otherUserId
    File? imageFile,
  }) async {
    String imageUrl = '';

    // 1. Handle Image Upload if exists
    if (imageFile != null) {
      final ref = _storage
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final String finalMessage = imageUrl.isNotEmpty && messageText.isEmpty 
        ? '📷 Photo' 
        : messageText;

    final now = FieldValue.serverTimestamp();

    // 2. Update/Create Session
    await _firestore.collection('chat_sessions').doc(chatId).set({
      'participants': [currentUid, otherUserId]..sort(),
      'lastMessage': finalMessage,
      'lastMessageSenderId': currentUid,
      'lastMessageTime': now,
      'unreadCounts.$otherUserId': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // 3. Add Message
    await _firestore
        .collection('chat_sessions')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUid,
      'receiverId': otherUserId,
      'text': messageText,
      'imageUrl': imageUrl, // Added image field
      'timestamp': now,
    });
  }

  // ─────────────────────────────
  // MARK AS READ
  // ─────────────────────────────
  Future<void> markAsRead(String chatId) async {
    await _firestore.collection('chat_sessions').doc(chatId).update({
      'unreadCounts.$currentUid': 0,
    });
  }

  // ─────────────────────────────
  // HELPERS
  // ─────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(dateTime);
    } else {
      return DateFormat('MM/dd/yy').format(dateTime);
    }
  }
}