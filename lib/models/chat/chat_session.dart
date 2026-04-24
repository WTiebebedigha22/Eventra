import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String id; // uid1_uid2 sorted ID
  final List<String> participants;

  final String lastMessage;
  final String lastMessageSenderId; // 🔥 Added this field
  final DateTime lastMessageTime;

  final Map<String, int> unreadCounts;

  ChatSession({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageSenderId, // 🔥 Added this
    required this.lastMessageTime,
    required this.unreadCounts,
  });

  // ─────────────────────────────
  // GET OTHER USER ID
  // ─────────────────────────────
  String getOtherUserId(String currentUserId) {
    try {
      return participants.firstWhere(
        (uid) => uid != currentUserId,
      );
    } catch (e) {
      return '';
    }
  }

  // ─────────────────────────────
  // FROM FIRESTORE (SAFE VERSION)
  // ─────────────────────────────
  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ChatSession(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '', // 🔥 Added this
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime.now(),

      // 🔥 SAFE CASTING (prevents crash)
      unreadCounts: (data['unreadCounts'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num).toInt())), // using num for safety
    );
  }

  // ─────────────────────────────
  // TO FIRESTORE
  // ─────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    };
  }

  // ─────────────────────────────
  // HELPER: unread for current user
  // ─────────────────────────────
  int unreadFor(String userId) {
    return unreadCounts[userId] ?? 0;
  }
}