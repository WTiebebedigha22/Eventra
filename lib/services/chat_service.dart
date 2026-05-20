import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: d['senderId'] as String,
      text: d['text'] as String,
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      read: d['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'read': read,
      };
}

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _currentUid => _auth.currentUser!.uid;

  /// Creates a stable chat ID from two user IDs (sorted so it's always the same)
  String chatId(String otherUid) {
    final ids = [_currentUid, otherUid]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  CollectionReference _chats() => _firestore.collection('chats');

  /// Ensure the chat document exists. Safe to call multiple times.
  Future<void> initChat(String otherUid, String otherName) async {
    final id = chatId(otherUid);
    final ref = _chats().doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [_currentUid, otherUid],
        'lastMessage': '',
        'lastSenderId': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Stream of all chats the current user is a participant in
  Stream<QuerySnapshot> myChats() {
    return _chats()
        .where('participants', arrayContains: _currentUid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Stream of messages in a given chat room
  Stream<QuerySnapshot> messages(String otherUid) {
    final id = chatId(otherUid);
    return _chats()
        .doc(id)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Send a message
  Future<void> sendMessage(String otherUid, String text) async {
    final id = chatId(otherUid);
    final chatRef = _chats().doc(id);
    final messagesRef = chatRef.collection('messages');

    final batch = _firestore.batch();

    final msgRef = messagesRef.doc();
    batch.set(msgRef, {
      'senderId': _currentUid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastSenderId': _currentUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Mark all unread messages from the other user as read
  Future<void> markAsRead(String otherUid) async {
    final id = chatId(otherUid);
    final unread = await _chats()
        .doc(id)
        .collection('messages')
        .where('senderId', isEqualTo: otherUid)
        .where('read', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Set/clear typing indicator for current user in a chat
  Future<void> setTyping(String otherUid, bool isTyping) async {
    final id = chatId(otherUid);
    await _chats().doc(id).collection('typing').doc(_currentUid).set({
      'isTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of whether the OTHER user is typing
  Stream<bool> isOtherTyping(String otherUid) {
    final id = chatId(otherUid);
    return _chats()
        .doc(id)
        .collection('typing')
        .doc(otherUid)
        .snapshots()
        .map((snap) => snap.data()?['isTyping'] as bool? ?? false);
  }

  /// Count of unread messages across all chats (for badge)
  Stream<int> unreadCount() {
    return _firestore
        .collectionGroup('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: _currentUid)
        .snapshots()
        .map((s) => s.docs.length);
  }
}