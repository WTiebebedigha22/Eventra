import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;
  final String? messageType;

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
  
  // Cache for chat IDs to prevent duplicate checks
  final Map<String, String> _chatIdCache = {};

  String? get _currentUid => _auth.currentUser?.uid;

  /// Creates a stable chat ID from two user IDs (sorted so it's always the same)
  String chatId(String otherUid) {
    if (_currentUid == null) throw Exception('User not logged in');
    
    // Clean the UIDs (in case they contain underscores)
    final cleanOtherUid = otherUid.split('_').first;
    final cleanCurrentUid = _currentUid!.split('_').first;
    
    final cacheKey = '${cleanCurrentUid}_$cleanOtherUid';
    if (_chatIdCache.containsKey(cacheKey)) {
      return _chatIdCache[cacheKey]!;
    }
    
    final ids = [cleanCurrentUid, cleanOtherUid]..sort();
    final sortedId = '${ids[0]}_${ids[1]}';
    _chatIdCache[cacheKey] = sortedId;
    
    print('📱 Generated chatId: $sortedId for users: ${ids[0]}, ${ids[1]}');
    return sortedId;
  }

  CollectionReference _chats() => _firestore.collection('chats');

  /// Ensure the chat document exists. Safe to call multiple times.
  Future<void> initChat(String otherUid, String otherName) async {
    if (_currentUid == null) throw Exception('User not logged in');
    
    final cleanOtherUid = otherUid.split('_').first;
    final cleanCurrentUid = _currentUid!.split('_').first;
    final String chatId = this.chatId(cleanOtherUid);
    final DocumentReference ref = _chats().doc(chatId);
    
    print('📱 Initializing chat: $chatId');
    print('📱 Participants: $cleanCurrentUid, $cleanOtherUid');
    
    try {
      final DocumentSnapshot snap = await ref.get();
      
      if (!snap.exists) {
        print('📝 Creating new chat document...');
        
        final Map<String, dynamic> chatData = {
          'participants': [cleanCurrentUid, cleanOtherUid],
          'participantNames': {
            cleanCurrentUid: _auth.currentUser?.displayName ?? 'User',
            cleanOtherUid: otherName,
          },
          'lastMessage': '',
          'lastSenderId': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        };
        
        await ref.set(chatData);
        print('✅ Chat document created: $chatId');
        
        // Verify creation
        final verifySnap = await ref.get();
        if (verifySnap.exists) {
          print('✅ Verified chat document exists');
        } else {
          print('❌ Chat document creation failed');
          throw Exception('Failed to create chat document');
        }
      } else {
        print('✅ Chat document already exists: $chatId');
        
        final data = snap.data() as Map<String, dynamic>;
        
        // Update if inactive
        if (data['isActive'] == false) {
          await ref.update({'isActive': true, 'updatedAt': FieldValue.serverTimestamp()});
          print('🔄 Reactivated chat');
        }
        
        // Fix participants if needed
        final List<dynamic> participants = data['participants'] ?? [];
        if (!participants.contains(cleanCurrentUid) || !participants.contains(cleanOtherUid)) {
          await ref.update({
            'participants': [cleanCurrentUid, cleanOtherUid],
          });
          print('🔄 Fixed participants');
        }
      }
    } catch (e) {
      print('❌ Error initializing chat: $e');
      rethrow;
    }
  }

  /// Get or create chat - ensures chat exists and returns the ID
  Future<String> getOrCreateChat(String otherUid, String otherName) async {
    await initChat(otherUid, otherName);
    return chatId(otherUid);
  }

  /// Stream of all chats the current user is a participant in
  Stream<QuerySnapshot> getConversationsStream() {
    if (_currentUid == null) return Stream.empty();
    
    final cleanCurrentUid = _currentUid!.split('_').first;
    
    return _chats()
        .where('participants', arrayContains: cleanCurrentUid)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error getting conversations: $error');
          return Stream.error(error);
        });
  }

  /// Stream of messages in a given chat room
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    try {
      return _chats()
          .doc(chatId)
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
    
    final cleanOtherUid = otherUid.split('_').first;
    final String chatId = this.chatId(cleanOtherUid);
    final DocumentReference chatRef = _chats().doc(chatId);
    
    // Ensure chat exists before sending message
    final snap = await chatRef.get();
    if (!snap.exists) {
      print('⚠️ Chat doesn\'t exist, creating it first...');
      await initChat(cleanOtherUid, 'User');
    }
    
    final CollectionReference messagesRef = chatRef.collection('messages');
    final WriteBatch batch = _firestore.batch();

    final DocumentReference msgRef = messagesRef.doc();
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
      'isActive': true,
    });

    await batch.commit();
    print('✅ Message sent to chat: $chatId');
  }

  /// Send a media message (image, audio, etc.)
  Future<void> sendMediaMessage(
    String otherUid,
    String mediaUrl,
    String mediaType,
  ) async {
    if (_currentUid == null) throw Exception('User not logged in');
    
    final cleanOtherUid = otherUid.split('_').first;
    final String chatId = this.chatId(cleanOtherUid);
    final DocumentReference chatRef = _chats().doc(chatId);
    
    // Ensure chat exists
    final snap = await chatRef.get();
    if (!snap.exists) {
      await initChat(cleanOtherUid, 'User');
    }
    
    final CollectionReference messagesRef = chatRef.collection('messages');
    final WriteBatch batch = _firestore.batch();

    final DocumentReference msgRef = messagesRef.doc();
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
      'isActive': true,
    });

    await batch.commit();
    print('✅ Media sent to chat: $chatId');
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
      print('✅ Marked ${unread.docs.length} messages as read');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Set/clear typing indicator for current user in a chat
  Future<void> setTyping(String otherUid, bool isTyping) async {
    if (_currentUid == null) return;
    
    try {
      final cleanOtherUid = otherUid.split('_').first;
      final String chatId = this.chatId(cleanOtherUid);
      final DocumentReference typingRef = _chats()
          .doc(chatId)
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
      // Silently fail - typing indicators are not critical
      print('Typing indicator error (non-critical): $e');
    }
  }

  /// Stream of whether the OTHER user is typing
  Stream<bool> isOtherTyping(String otherUid) {
    if (_currentUid == null) return Stream.value(false);
    
    try {
      final cleanOtherUid = otherUid.split('_').first;
      final String chatId = this.chatId(cleanOtherUid);
      
      return _chats()
          .doc(chatId)
          .collection('typing')
          .doc(cleanOtherUid)
          .snapshots()
          .map((snap) {
            if (!snap.exists) return false;
            final data = snap.data();
            if (data == null) return false;
            
            final isTyping = data['isTyping'] as bool? ?? false;
            final updatedAt = data['updatedAt'] as Timestamp?;
            
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

  /// Count of unread messages across all chats (for badge) - FUTURE (single value)
  Future<int> getTotalUnreadCount() async {
    if (_currentUid == null) return 0;
    
    final cleanCurrentUid = _currentUid!.split('_').first;
    int totalUnread = 0;
    
    try {
      final chatsSnapshot = await _chats()
          .where('participants', arrayContains: cleanCurrentUid)
          .where('isActive', isEqualTo: true)
          .get();
      
      for (final chatDoc in chatsSnapshot.docs) {
        final chatId = chatDoc.id;
        final unreadSnapshot = await _chats()
            .doc(chatId)
            .collection('messages')
            .where('read', isEqualTo: false)
            .where('senderId', isNotEqualTo: _currentUid)
            .count()
            .get();
        
        totalUnread += (unreadSnapshot.count ?? 0);
      }
    } catch (e) {
      print('Error getting unread count: $e');
    }
    
    return totalUnread;
  }

  /// Stream of unread count (real-time for badge)
  Stream<int> getUnreadCountStream() {
    if (_currentUid == null) return Stream.value(0);
    
    final controller = StreamController<int>.broadcast();
    final cleanCurrentUid = _currentUid!.split('_').first;
    
    _chats()
        .where('participants', arrayContains: cleanCurrentUid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((chatsSnapshot) async {
          int totalUnread = 0;
          
          for (final chatDoc in chatsSnapshot.docs) {
            final chatId = chatDoc.id;
            try {
              final unreadSnapshot = await _chats()
                  .doc(chatId)
                  .collection('messages')
                  .where('read', isEqualTo: false)
                  .where('senderId', isNotEqualTo: _currentUid)
                  .count()
                  .get();
              
              totalUnread += (unreadSnapshot.count ?? 0);
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
    
    return controller.stream;
  }

  /// Delete entire conversation (soft delete)
  Future<void> deleteConversation(String chatId) async {
    if (_currentUid == null) return;
    
    try {
      await _chats().doc(chatId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Conversation $chatId soft deleted');
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }
  
  /// Permanently delete conversation (hard delete)
  Future<void> permanentlyDeleteConversation(String chatId) async {
    if (_currentUid == null) return;
    
    try {
      final messages = await _chats()
          .doc(chatId)
          .collection('messages')
          .get();
      
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      
      final typingDocs = await _chats()
          .doc(chatId)
          .collection('typing')
          .get();
      
      for (final doc in typingDocs.docs) {
        batch.delete(doc.reference);
      }
      
      batch.delete(_chats().doc(chatId));
      
      await batch.commit();
      print('✅ Conversation $chatId permanently deleted');
    } catch (e) {
      print('Error permanently deleting conversation: $e');
      rethrow;
    }
  }

  /// Get user profile information
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final cleanUid = uid.split('_').first;
      final doc = await _firestore.collection('users').doc(cleanUid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Stream user profile for real-time updates
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    final cleanUid = uid.split('_').first;
    return _firestore
        .collection('users')
        .doc(cleanUid)
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
    final cleanUid = uid.split('_').first;
    return _firestore
        .collection('users')
        .doc(cleanUid)
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
    
    final cleanUserId = userId.split('_').first;
    final cleanCurrentUid = _currentUid!.split('_').first;
    
    try {
      await _firestore
          .collection('users')
          .doc(cleanCurrentUid)
          .collection('blocked')
          .doc(cleanUserId)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
        'userId': cleanUserId,
      });
      print('✅ User $cleanUserId blocked');
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock user
  Future<void> unblockUser(String userId) async {
    if (_currentUid == null) return;
    
    final cleanUserId = userId.split('_').first;
    final cleanCurrentUid = _currentUid!.split('_').first;
    
    try {
      await _firestore
          .collection('users')
          .doc(cleanCurrentUid)
          .collection('blocked')
          .doc(cleanUserId)
          .delete();
      print('✅ User $cleanUserId unblocked');
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    if (_currentUid == null) return false;
    
    final cleanUserId = userId.split('_').first;
    final cleanCurrentUid = _currentUid!.split('_').first;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(cleanCurrentUid)
          .collection('blocked')
          .doc(cleanUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking block status: $e');
      return false;
    }
  }
  
  /// Clear chat ID cache (useful on logout)
  void clearCache() {
    _chatIdCache.clear();
    print('Chat cache cleared');
  }
}

extension ChatUtils on ChatService {
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