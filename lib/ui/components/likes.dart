import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeButton extends StatefulWidget {
  final String postId;
  final List<String> likes;
  final String collection; // Add this to distinguish between 'events' and 'posts'

  const LikeButton({
    super.key, 
    required this.postId, 
    required this.likes, 
    this.collection = 'events', // Default to events
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late List<String> _localLikes;
  late bool _isLiked;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _localLikes = List.from(widget.likes);
    _isLiked = _localLikes.contains(_currentUid);
  }

  // Synchronize state if the parent widget updates the list
  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.likes != oldWidget.likes) {
      _localLikes = List.from(widget.likes);
      _isLiked = _localLikes.contains(_currentUid);
    }
  }

  Future<void> _handleLike() async {
    if (_currentUid.isEmpty) return;

    HapticFeedback.lightImpact();

    // 1. Optimistic UI Update (Change the UI immediately)
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _localLikes.remove(_currentUid);
      } else {
        _isLiked = true;
        _localLikes.add(_currentUid);
      }
    });

    // 2. Update the Database
    final docRef = FirebaseFirestore.instance
        .collection(widget.collection)
        .doc(widget.postId);

    try {
      if (_isLiked) {
        await docRef.update({
          'likes': FieldValue.arrayUnion([_currentUid])
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayRemove([_currentUid])
        });
      }
    } catch (e) {
      // 3. Rollback if the DB call fails
      debugPrint("Error updating likes: $e");
      setState(() {
        if (_isLiked) {
          _isLiked = false;
          _localLikes.remove(_currentUid);
        } else {
          _isLiked = true;
          _localLikes.add(_currentUid);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't update like. Check connection.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleLike,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                key: ValueKey<bool>(_isLiked),
                color: _isLiked ? const Color(0xFFE91E63) : Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${_localLikes.length}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 1))],
          ),
        ),
      ],
    );
  }
}