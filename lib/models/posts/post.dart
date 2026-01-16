import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String creatorId; 
  final String? username;
  final String? userProfileUrl;
  final String content;
  final String? mediaUrl;
  final DateTime timestamp;
  final List<String> likes;
  final int commentCount;
  final DateTime? eventDate;
  final String? location;

  Post({
    required this.id,
    required this.creatorId,
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

  int get likeCount => likes.length;

  /// Converts the Post object into a Map for the EventCard component
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'userName': username ?? 'Anonymous',
      'userProfile': userProfileUrl ?? '',
      'description': content,
      'imageUrl': mediaUrl,
      'timestamp': timestamp,
      'likes': likes,
      'commentCount': commentCount,
      'eventDate': eventDate,
      'location': location ?? 'Unknown Location',
    };
  }

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final Timestamp? postTimestamp = data['timestamp'] as Timestamp?;
    final Timestamp? eventTimestamp = data['eventDate'] as Timestamp?;

    return Post(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      userProfileUrl: data['userProfileUrl'],
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      timestamp: postTimestamp?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      eventDate: eventTimestamp?.toDate(),
      location: data['location'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'username': username,
      'userProfileUrl': userProfileUrl,
      'content': content,
      'mediaUrl': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': likes,
      'commentCount': commentCount,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'location': location,
    };
  }
}