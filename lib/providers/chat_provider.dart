import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service;
  ChatProvider(this._service);

  bool _sending = false;
  bool get sending => _sending;

  Stream<QuerySnapshot> myChats() => _service.myChats();

  Stream<QuerySnapshot> messages(String otherUid) => _service.messages(otherUid);

  Stream<bool> isOtherTyping(String otherUid) => _service.isOtherTyping(otherUid);

  Stream<int> unreadCount() => _service.unreadCount();

  Future<void> initChat(String otherUid, String otherName) =>
      _service.initChat(otherUid, otherName);

  Future<void> sendMessage(String otherUid, String text) async {
    if (text.trim().isEmpty) return;
    _sending = true;
    notifyListeners();
    try {
      await _service.sendMessage(otherUid, text);
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String otherUid) => _service.markAsRead(otherUid);

  Future<void> setTyping(String otherUid, bool isTyping) =>
      _service.setTyping(otherUid, isTyping);
}