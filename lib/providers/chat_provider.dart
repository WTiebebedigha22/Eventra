import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service;
  
  bool _sending = false;
  bool _loading = false;
  String? _error;
  Map<String, bool> _typingStatus = {};
  Map<String, int> _unreadCounts = {};
  int _totalUnreadCount = 0;

  ChatProvider(this._service);

  // Getters
  bool get sending => _sending;
  bool get loading => _loading;
  String? get error => _error;
  Map<String, bool> get typingStatus => _typingStatus;
  int get totalUnreadCount => _totalUnreadCount;
  
  // Streams
  Stream<QuerySnapshot> getConversations() => _service.getConversationsStream();
  
  Stream<QuerySnapshot> getMessages(String chatId) => 
      _service.getMessagesStream(chatId);
  
  Stream<bool> isOtherTyping(String otherUid) => 
      _service.isOtherTyping(otherUid);
  
  Stream<bool> isUserOnline(String uid) => _service.isUserOnline(uid);
  
  // Unread count stream (real-time)
  void listenToUnreadCount() {
    _service.getUnreadCountStream().listen((count) {
      _totalUnreadCount = count;
      notifyListeners();
    });
  }
  
  // Load unread count once
  Future<void> loadUnreadCount() async {
    _totalUnreadCount = await _service.getTotalUnreadCount();
    notifyListeners();
  }

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

  // Get or create chat
  Future<String?> getOrCreateChat(String otherUid, String otherName) async {
    _setLoading(true);
    _clearError();
    
    try {
      final chatId = await _service.getOrCreateChat(otherUid, otherName);
      return chatId;
    } catch (e) {
      _setError('Failed to get/create chat: $e');
      return null;
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

  // Mark messages as read
  Future<void> markAsRead(String chatId) async {
    try {
      await _service.markAsRead(chatId);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // Set typing indicator
  void setTyping(String otherUid, bool isTyping) {
    _typingStatus[otherUid] = isTyping;
    notifyListeners();
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

  // Permanently delete conversation
  Future<bool> permanentlyDeleteConversation(String chatId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _service.permanentlyDeleteConversation(chatId);
      return true;
    } catch (e) {
      _setError('Failed to permanently delete conversation: $e');
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

  // Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      return await _service.isUserBlocked(userId);
    } catch (e) {
      debugPrint('Error checking block status: $e');
      return false;
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

  // Clear cache (call on logout)
  void clearCache() {
    _service.clearCache();
    _typingStatus.clear();
    _unreadCounts.clear();
    _totalUnreadCount = 0;
    _clearError();
    notifyListeners();
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

// Extension for easier provider access
extension ChatProviderExtension on BuildContext {
  ChatProvider get chatProvider => Provider.of<ChatProvider>(this);
  ChatProvider get chatProviderListen => Provider.of<ChatProvider>(this, listen: true);
}