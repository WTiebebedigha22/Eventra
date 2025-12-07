import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final _ref = FirebaseFirestore.instance.collection('chats');

  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _ref
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) =>
            snap.docs.map((e) => ChatMessage.fromMap(e.data(), e.id)).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
  }) async {
    await _ref.doc(chatId).collection('messages').add(message.toMap());
  }
}
