import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/posts/post.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  final VoidCallback onDelete;

  const PostDetailScreen({super.key, required this.post, required this.onDelete});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.white),
              title: const Text('Share Post', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Post', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletion(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Delete Post?", style: TextStyle(color: Colors.white)),
        content: const Text("This action will remove the post from your profile.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white))),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to profile
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isLiked = post.likes.contains(auth.userId);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Post", style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Header (New)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[900],
                    backgroundImage: post.userProfileUrl != null ? NetworkImage(post.userProfileUrl!) : null,
                    child: post.userProfileUrl == null ? const Icon(Icons.person, size: 18, color: Colors.white24) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.username ?? 'Anonymous', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                        if (post.location != null)
                          Text(post.location!, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Media Section
            Hero(
              tag: 'post_${post.id}',
              child: post.mediaUrl != null
                  ? Image.network(post.mediaUrl!, width: double.infinity, fit: BoxFit.contain)
                  : Container(
                      width: double.infinity,
                      height: 250,
                      color: const Color(0xFF181818),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Text(post.content, style: const TextStyle(color: Colors.black, fontSize: 18), textAlign: TextAlign.center),
                    ),
            ),

            // 3. Interaction Bar (New)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.white),
                    onPressed: () {
                      context.read<PostProvider>().toggleLike(post.id, post.creatorId, auth.displayName);
                    },
                  ),
                  Text('${post.likeCount}', style: const TextStyle(color: Colors.black)),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text('${post.commentCount}', style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),

            // 4. Content & Dates
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.mediaUrl != null) ...[
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '${post.username} ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          TextSpan(text: post.content, style: const TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Display Event Date if it exists
                  if (post.eventDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.event, size: 14, color: Color(0xFF3E5992)),
                          const SizedBox(width: 4),
                          Text(
                            "Event on ${DateFormat('MMM dd, yyyy').format(post.eventDate!)}",
                            style: const TextStyle(color: Color(0xFF3E5992), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                  Text(
                    DateFormat('MMMM dd, yyyy • hh:mm a').format(post.timestamp),
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}