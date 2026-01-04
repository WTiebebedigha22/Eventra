import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String? username;        // Added for UI
  final String? userProfileUrl; // Added for UI
  final String content;
  final String? mediaUrl;
  final DateTime timestamp;
  final List<String> likes;     // Changed from 'var' to 'List<String>'
  final int commentCount;
  final DateTime? eventDate;
  final String? location;

  Post({
    required this.id,
    required this.userId,
    this.username,
    this.userProfileUrl,
    required this.content,
    required this.mediaUrl,
    required this.timestamp,
    this.likes = const [],
    this.commentCount = 0,
    this.eventDate,
    this.location,
  });

  // Helper getter to keep your likeCount logic working
  int get likeCount => likes.length;

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final Timestamp? postTimestamp = data['timestamp'];
    final Timestamp? eventTimestamp = data['eventDate'];

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous', // Map from Firestore
      userProfileUrl: data['userProfileUrl'],     // Map from Firestore
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      timestamp: postTimestamp?.toDate() ?? DateTime.now(),
      // Ensure likes is always a List<String>
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      eventDate: eventTimestamp?.toDate(),
      location: data['location'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userProfileUrl': userProfileUrl,
      'content': content,
      'mediaUrl': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': likes, // Stores list of user IDs
      'commentCount': commentCount,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'location': location,
    };
  }
}