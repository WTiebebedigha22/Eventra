import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _col = FirebaseFirestore.instance.collection('chats');

  Stream<List<Map<String, dynamic>>> messagesStream(String chatId) {
    final sub = _col.doc(chatId).collection('messages').orderBy('createdAt').snapshots();
    return sub.map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> sendMessage(String chatId, Map<String, dynamic> message) async {
    await _col.doc(chatId).collection('messages').add(message);
    await _col.doc(chatId).set({
      'lastMessage': message['message'] ?? '',
      'lastAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
