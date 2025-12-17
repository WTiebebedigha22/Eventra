import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String content;
  final String? mediaUrl;
  final DateTime timestamp;
  final int likeCount;
  final int commentCount;
  
  final DateTime? eventDate;
  final String? location;

  var likes; 

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.mediaUrl,
    required this.timestamp,
    this.likeCount = 0,
    this.commentCount = 0,
    this.eventDate,
    this.location,
  });

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final Timestamp? postTimestamp = data['timestamp'];
    final Timestamp? eventTimestamp = data['eventDate'];

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      timestamp: postTimestamp?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      eventDate: eventTimestamp?.toDate(),
      location: data['location'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'mediaUrl': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'location': location,
    };
  }
}