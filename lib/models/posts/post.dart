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
  // New: Field to support category filtering
  final String category;

  Post({
    required this.id,
    required this.creatorId,
    this.username,
    this.userProfileUrl,
    required this.content,
    this.mediaUrl,
    required this.timestamp,
    this.likes = const [],
    this.commentCount = 0,
    this.eventDate,
    this.location,
    this.category = 'General', // Default value
  });

  int get likeCount => likes.length;

  /// Converts the Post object into a Map for the UI components
  /// Keys here match what EventCard and MasonryTile expect
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'username': username ?? 'Anonymous',
      'userProfileUrl': userProfileUrl ?? '',
      'content': content,
      'description': content, // Aliased for components using 'description'
      'mediaUrl': mediaUrl,
      'imageUrl': mediaUrl,    // Aliased for components using 'imageUrl'
      'timestamp': timestamp,
      'likes': likes,
      'commentCount': commentCount,
      'eventDate': eventDate,
      'location': location ?? 'Unknown Location',
      'category': category,
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
      content: data['content'] ?? data['description'] ?? '', // Handles both keys
      mediaUrl: data['mediaUrl'] ?? data['imageUrl'],        // Handles both keys
      timestamp: postTimestamp?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      eventDate: eventTimestamp?.toDate(),
      location: data['location'],
      category: data['category'] ?? 'General',
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
      'category': category,
    };
  }
}