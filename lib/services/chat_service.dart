import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;
  final String? messageType; // 'text', 'image', 'audio', 'video'

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.read = false,
    this.messageType,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Message data is null');
    }
    
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
      messageType: data['messageType'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'read': read,
        if (messageType != null) 'messageType': messageType,
      };
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  /// Creates a stable chat ID from two user IDs (sorted so it's always the same)
  String chatId(String otherUid) {
    if (_currentUid == null) throw Exception('User not logged in');
    final ids = [_currentUid!, otherUid]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  CollectionReference _chats() => _firestore.collection('chats');

  /// Ensure the chat document exists. Safe to call multiple times.
  Future<void> initChat(String otherUid, String otherName) async {
    if (_currentUid == null) throw Exception('User not logged in');
    
    final id = chatId(otherUid);
    final ref = _chats().doc(id);
    
    try {
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'participants': [_currentUid, otherUid],
          'participantNames': {
            _currentUid: _auth.currentUser?.displayName ?? 'User',
            otherUid: otherName,
          },
          'lastMessage': '',
          'lastSenderId': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing chat: $e');
      rethrow;
    }
  }

  /// Stream of all chats the current user is a participant in
  Stream<QuerySnapshot> getConversationsStream() {
    if (_currentUid == null) return Stream.empty();
    
    return _chats()
        .where('participants', arrayContains: _currentUid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error getting conversations: $error');
          return Stream.error(error);
        });
  }

  /// Stream of messages in a given chat room
  Stream<QuerySnapshot> getMessagesStream(String otherUid) {
    try {
      final id = chatId(otherUid);
      return _chats()
          .doc(id)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .handleError((error) {
            print('Error getting messages: $error');
            return Stream.error(error);
          });
    } catch (e) {
      print('Error in getMessagesStream: $e');
      return Stream.error(e);
    }
  }

  /// Send a text message
  Future<void> sendMessage(String otherUid, String text) async {
    if (_currentUid == null) throw Exception('User not logged in');
    if (text.trim().isEmpty) return;
    
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
      'messageType': 'text',
    });

    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastSenderId': _currentUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Send a media message (image, audio, etc.)
  Future<void> sendMediaMessage(
    String otherUid,
    String mediaUrl,
    String mediaType,
  ) async {
    if (_currentUid == null) throw Exception('User not logged in');
    
    final id = chatId(otherUid);
    final chatRef = _chats().doc(id);
    final messagesRef = chatRef.collection('messages');

    final batch = _firestore.batch();

    final msgRef = messagesRef.doc();
    batch.set(msgRef, {
      'senderId': _currentUid,
      'text': mediaUrl,
      'messageType': mediaType,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    String previewText = '';
    switch (mediaType) {
      case 'image':
        previewText = '📷 Photo';
        break;
      case 'audio':
        previewText = '🎵 Voice message';
        break;
      case 'video':
        previewText = '🎥 Video';
        break;
      default:
        previewText = 'Media';
    }

    batch.update(chatRef, {
      'lastMessage': previewText,
      'lastSenderId': _currentUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Mark all unread messages from the other user as read
  Future<void> markAsRead(String chatId) async {
    if (_currentUid == null) return;
    
    try {
      final unread = await _chats()
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _currentUid)
          .where('read', isEqualTo: false)
          .get();

      if (unread.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Set/clear typing indicator for current user in a chat
  Future<void> setTyping(String otherUid, bool isTyping) async {
    if (_currentUid == null) return;
    
    try {
      final id = chatId(otherUid);
      final typingRef = _chats()
          .doc(id)
          .collection('typing')
          .doc(_currentUid);
      
      if (isTyping) {
        await typingRef.set({
          'isTyping': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await typingRef.delete();
      }
    } catch (e) {
      print('Error setting typing status: $e');
    }
  }

  /// Stream of whether the OTHER user is typing
  Stream<bool> isOtherTyping(String otherUid) {
    if (_currentUid == null) return Stream.value(false);
    
    try {
      final id = chatId(otherUid);
      return _chats()
          .doc(id)
          .collection('typing')
          .doc(otherUid)
          .snapshots()
          .map((snap) {
            if (!snap.exists) return false;
            final data = snap.data();
            if (data == null) return false;
            
            final isTyping = data['isTyping'] as bool? ?? false;
            final updatedAt = data['updatedAt'] as Timestamp?;
            
            // Typing indicator expires after 3 seconds
            if (updatedAt != null && isTyping) {
              final diff = DateTime.now().difference(updatedAt.toDate());
              if (diff.inSeconds > 3) {
                return false;
              }
            }
            
            return isTyping;
          })
          .handleError((error) {
            print('Error checking typing status: $error');
            return Stream.value(false);
          });
    } catch (e) {
      print('Error in isOtherTyping: $e');
      return Stream.value(false);
    }
  }

  // FIXED: getUnreadCount without collectionGroup query
  /// Count of unread messages across all chats (for badge)
  Stream<int> getUnreadCount() {
    if (_currentUid == null) return Stream.value(0);
    
    final controller = StreamController<int>.broadcast();
    
    // Listen to all chats the user is part of
    _chats()
        .where('participants', arrayContains: _currentUid)
        .snapshots()
        .listen((chatsSnapshot) async {
          int totalUnread = 0;
          
          for (final chatDoc in chatsSnapshot.docs) {
            final chatId = chatDoc.id;
            
            // For each chat, count unread messages where user is not the sender
            try {
              final unreadSnapshot = await _chats()
                  .doc(chatId)
                  .collection('messages')
                  .where('read', isEqualTo: false)
                  .where('senderId', isNotEqualTo: _currentUid)
                  .count()
                  .get();
              
              totalUnread += unreadSnapshot.count!;
            } catch (e) {
              print('Error counting unread for chat $chatId: $e');
            }
          }
          
          if (!controller.isClosed) {
            controller.add(totalUnread);
          }
        }, onError: (error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });
    
    return controller.stream.handleError((error) {
      print('Error getting unread count: $error');
      return 0;
    });
  }

  // Alternative: Simpler Future-based unread count
  Future<int> getUnreadCountOnce() async {
    if (_currentUid == null) return 0;
    
    final chatsSnapshot = await _chats()
        .where('participants', arrayContains: _currentUid)
        .get();
    
    int totalUnread = 0;
    
    for (final chatDoc in chatsSnapshot.docs) {
      final chatId = chatDoc.id;
      
      final unreadSnapshot = await _chats()
          .doc(chatId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('senderId', isNotEqualTo: _currentUid)
          .count()
          .get();
      
      totalUnread += unreadSnapshot.count!;
    }
    
    return totalUnread;
  }

  /// Delete entire conversation
  Future<void> deleteConversation(String chatId) async {
    if (_currentUid == null) return;
    
    try {
      // Get all messages in the conversation
      final messages = await _chats()
          .doc(chatId)
          .collection('messages')
          .get();
      
      // Delete in batch
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete typing indicators
      final typingDocs = await _chats()
          .doc(chatId)
          .collection('typing')
          .get();
      
      for (final doc in typingDocs.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the chat document itself
      batch.delete(_chats().doc(chatId));
      
      await batch.commit();
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Get user profile information
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Stream user profile for real-time updates
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .handleError((error) {
          print('Error getting user profile stream: $error');
          return Stream.error(error);
        });
  }

  /// Format timestamp for display
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }
    
    final DateTime now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.month}/${date.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  /// Check if user is online
  Stream<bool> isUserOnline(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data();
          if (data == null) return false;
          return data['isOnline'] as bool? ?? false;
        });
  }

  /// Block user
  Future<void> blockUser(String userId) async {
    if (_currentUid == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('blocked')
          .doc(userId)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock user
  Future<void> unblockUser(String userId) async {
    if (_currentUid == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('blocked')
          .doc(userId)
          .delete();
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    if (_currentUid == null) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('blocked')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking block status: $e');
      return false;
    }
  }
}

// Extension for additional chat utilities
extension ChatUtils on ChatService {
  /// Get chat participants names
  Future<Map<String, String>> getParticipantsNames(String chatId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      
      if (!doc.exists) return {};
      
      final data = doc.data();
      if (data == null) return {};
      
      final participantNames = data['participantNames'] as Map<String, dynamic>?;
      if (participantNames == null) return {};
      
      return participantNames.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('Error getting participants names: $e');
      return {};
    }
  }
}