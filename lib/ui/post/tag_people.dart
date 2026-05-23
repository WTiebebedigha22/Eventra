import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

// --- Color Palette ---
const Color primaryColor = Color(0xFF6C63FF); // Deep Purple Accent
const Color backgroundColor = Colors.white;
const Color textColor = Color(0xFF1C1E21);
const Color subtleText = Color(0xFF7A7E8B);
const Color inputBg = Color(0xFFF8F9FA);
const Color dividerColor = Color(0xFFEEF2F6);

class TagPeopleScreen extends StatefulWidget {
  final List<String>? initiallySelected;
  final Function(List<String>)? onTagged;

  const TagPeopleScreen({
    super.key,
    this.initiallySelected,
    this.onTagged,
  });

  @override
  State<TagPeopleScreen> createState() => _TagPeopleScreenState();
}

class _TagPeopleScreenState extends State<TagPeopleScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  Timer? _debounce;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initiallySelected != null) {
      _selectedUserIds.addAll(widget.initiallySelected!);
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _isSearching = _searchQuery.isNotEmpty;
      });
    });
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _confirmTagging() {
    if (widget.onTagged != null) {
      widget.onTagged!(_selectedUserIds.toList());
    }
    Navigator.pop(context, _selectedUserIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Tag People',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _selectedUserIds.isEmpty ? null : _confirmTagging,
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
            ),
            child: Text(
              'Done (${_selectedUserIds.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isSearching
                ? _buildSearchResults(currentUserId)
                : _buildSuggestedUsers(currentUserId),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(fontSize: 16, color: textColor),
        decoration: InputDecoration(
          hintText: 'Search by username...',
          hintStyle: TextStyle(color: subtleText.withOpacity(0.5), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: primaryColor, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSearchResults(String? currentUserId) {
    if (_searchQuery.isEmpty) {
      return const Center(
        child: Text('Type to search for users...'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery)
          .where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final users = snapshot.data?.docs.where((doc) => doc.id != currentUserId).toList() ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No users found for "$_searchQuery"',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final userId = user.id;
            final isSelected = _selectedUserIds.contains(userId);

            return _buildUserTile(
              username: data['username'] ?? 'User',
              displayName: data['displayName'],
              photoUrl: data['photoURL'],
              userId: userId,
              isSelected: isSelected,
              onTap: () => _toggleSelection(userId),
            );
          },
        );
      },
    );
  }

  Widget _buildSuggestedUsers(String? currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('followerCount', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs.where((doc) => doc.id != currentUserId).toList() ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Text('No users found'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: dividerColor),
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final userId = user.id;
            final isSelected = _selectedUserIds.contains(userId);

            return _buildUserTile(
              username: data['username'] ?? 'User',
              displayName: data['displayName'],
              photoUrl: data['photoURL'],
              userId: userId,
              isSelected: isSelected,
              onTap: () => _toggleSelection(userId),
            );
          },
        );
      },
    );
  }

  Widget _buildUserTile({
    required String username,
    required String? displayName,
    required String? photoUrl,
    required String userId,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImageProvider(photoUrl)
            : null,
        backgroundColor: Colors.grey.shade200,
        child: photoUrl == null || photoUrl.isEmpty
            ? Icon(Icons.person, size: 22, color: Colors.grey[600])
            : null,
      ),
      title: Text(
        displayName ?? username,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        '@$username',
        style: TextStyle(fontSize: 13, color: subtleText),
      ),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check_circle, size: 20, color: primaryColor)
            : null,
      ),
      onTap: onTap,
    );
  }
}