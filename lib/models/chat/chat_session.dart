import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String id; // The "uid1_uid2" sorted ID
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts; // Track unread per user

  ChatSession({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
  });

  /// Logic to find the ID of the person the current user is talking to
  String getOtherUserId(String currentUserId) {
    return participants.firstWhere((uid) => uid != currentUserId, orElse: () => '');
  }

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    };
  }
}