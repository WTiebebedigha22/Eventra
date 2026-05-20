import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service;
  
  bool _sending = false;
  bool _loading = false;
  String? _error;
  Map<String, bool> _typingStatus = {};
  Map<String, int> _unreadCounts = {};

  ChatProvider(this._service);

  // Getters
  bool get sending => _sending;
  bool get loading => _loading;
  String? get error => _error;
  Map<String, bool> get typingStatus => _typingStatus;
  
  // Streams
  Stream<QuerySnapshot> getConversations() => _service.getConversationsStream();
  
  Stream<QuerySnapshot> getMessages(String otherUid) => 
      _service.getMessagesStream(otherUid);
  
  Stream<bool> isOtherTyping(String otherUid) => 
      _service.isOtherTyping(otherUid);
  
  Stream<int> getUnreadCount() => _service.getUnreadCount();
  
  Stream<bool> isUserOnline(String uid) => _service.isUserOnline(uid);

  // Initialize chat
  Future<bool> initChat(String otherUid, String otherName) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _service.initChat(otherUid, otherName);
      return true;
    } catch (e) {
      _setError('Failed to initialize chat: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send message with retry logic
  Future<bool> sendMessage(String otherUid, String text, {int retryCount = 0}) async {
    if (text.trim().isEmpty) return false;
    
    _sending = true;
    _clearError();
    notifyListeners();
    
    try {
      await _service.sendMessage(otherUid, text);
      return true;
    } catch (e) {
      if (retryCount < 3) {
        // Retry up to 3 times
        await Future.delayed(Duration(seconds: 1));
        return sendMessage(otherUid, text, retryCount: retryCount + 1);
      }
      _setError('Failed to send message: $e');
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  // Send media message
  Future<bool> sendMediaMessage(
    String otherUid,
    String mediaUrl,
    String mediaType,
  ) async {
    _sending = true;
    _clearError();
    notifyListeners();
    
    try {
      await _service.sendMediaMessage(otherUid, mediaUrl, mediaType);
      return true;
    } catch (e) {
      _setError('Failed to send media: $e');
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  // Mark messages as read with loading state
  Future<void> markAsRead(String chatId) async {
    try {
      await _service.markAsRead(chatId);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // Set typing indicator with debounce
  void setTyping(String otherUid, bool isTyping) {
    // Update local state
    _typingStatus[otherUid] = isTyping;
    notifyListeners();
    
    // Debounce typing updates to avoid excessive writes
    _service.setTyping(otherUid, isTyping);
  }

  // Delete conversation
  Future<bool> deleteConversation(String chatId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _service.deleteConversation(chatId);
      return true;
    } catch (e) {
      _setError('Failed to delete conversation: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Block user
  Future<bool> blockUser(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _service.blockUser(userId);
      return true;
    } catch (e) {
      _setError('Failed to block user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Unblock user
  Future<bool> unblockUser(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _service.unblockUser(userId);
      return true;
    } catch (e) {
      _setError('Failed to unblock user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      return await _service.getUserProfile(uid);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update unread count for specific chat
  Future<void> updateUnreadCount(String chatId) async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        final data = chatDoc.data();
        if (data != null && data.containsKey('unreadCounts')) {
          final counts = data['unreadCounts'] as Map<String, dynamic>?;
          if (counts != null) {
            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            if (currentUid != null) {
              _unreadCounts[chatId] = counts[currentUid] as int? ?? 0;
              notifyListeners();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating unread count: $e');
    }
  }

  // Get unread count for specific chat
  int getUnreadCountForChat(String chatId) {
    return _unreadCounts[chatId] ?? 0;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Dispose
  @override
  void dispose() {
    _typingStatus.clear();
    _unreadCounts.clear();
    super.dispose();
  }
}
