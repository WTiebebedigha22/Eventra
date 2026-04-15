import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; 

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final PageController _imagePageController = PageController();

  static const Color bravelionBlue = Colors.deepPurpleAccent;
  static const Color jijiGreen = Colors.deepPurple;
  static const Color textMain = Color(0xFF1C1E21);
  static const Color textSub = Color(0xFF65676B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildQuickChatInput(context),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('events').doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading event"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: bravelionBlue));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) return _buildNotFound(context);

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          // Logic to handle both single imageUrl and multiple mediaUrls
          List<String> images = [];
          if (data['mediaUrls'] != null) {
            images = List<String>.from(data['mediaUrls']);
          } else if (data['imageUrl'] != null) {
            images = [data['imageUrl']];
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: bravelionBlue,
                leading: _buildCircleBackButton(context),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageCarousel(images),
                      _buildGradientOverlay(),
                      
                      // Page Indicator
                      if (images.length > 1)
                        Positioned(
                          bottom: 60,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _imagePageController,
                              count: images.length,
                              effect: const ScrollingDotsEffect(
                                dotWidth: 8,
                                dotHeight: 8,
                                activeDotColor: Colors.white,
                                dotColor: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                        
                      Positioned(bottom: 20, left: 20, child: _buildPriceBadge(data['price'])),
                      
                      // Image Count Badge
                      if (images.length > 1)
                        Positioned(
                          bottom: 20, 
                          right: 20, 
                          child: _buildCountBadge(images.length),
                        ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserSection(context, data),
                      const SizedBox(height: 20),
                      Text(data['title'] ?? 'Untitled', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(data['description'] ?? '', style: const TextStyle(fontSize: 15, color: textSub, height: 1.5)),
                      const SizedBox(height: 20),
                      const Divider(),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text("Recommended for you", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 210,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('events').limit(6).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 20),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          if (doc.id == widget.eventId) return const SizedBox();
                          return _buildRecommendationCard(doc.data() as Map<String, dynamic>);
                        },
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  // --- Image Carousel Support ---
  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) return Container(color: Colors.grey[300]);
    
    return PageView.builder(
      controller: _imagePageController,
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Future logic for full-screen image view
          },
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
          ),
        );
      },
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.image, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text("$count", style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // --- The rest of your existing UI helpers stay the same ---
  // ... _buildQuickChatInput, _buildRecommendationCard, _buildUserSection, etc.
  
  Widget _buildQuickChatInput(BuildContext context) {
    final List<String> suggestions = ["Are the tickets still available?", "What is the final price?", "When is this event starting?", "I'm interested!"];
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10, left: 16, right: 16, top: 10),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 35,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _sendMessage(context, suggestions[i]),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(20)),
                  alignment: Alignment.center,
                  child: Text(suggestions[i], style: const TextStyle(fontSize: 12, color: textMain)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
                  child: const TextField(decoration: InputDecoration(hintText: "Type a message...", border: InputBorder.none)),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: jijiGreen,
                child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () => _sendMessage(context, "Direct Interest")),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> data) {
    // Check for mediaUrls in recommendations too
    String thumb = '';
    if (data['mediaUrls'] != null && (data['mediaUrls'] as List).isNotEmpty) {
      thumb = data['mediaUrls'][0];
    } else {
      thumb = data['imageUrl'] ?? '';
    }

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(thumb, height: 110, width: 160, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
          ),
          const SizedBox(height: 8),
          Text(data['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text("₦${data['price'] ?? '0'}", style: const TextStyle(color: jijiGreen, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, String msg) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sending: $msg"), backgroundColor: bravelionBlue, behavior: SnackBarBehavior.floating));
  }

  Widget _buildGradientOverlay() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black26, Colors.transparent, Colors.black54],
        ),
      ),
    );
  }

  Widget _buildPriceBadge(dynamic price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: jijiGreen, borderRadius: BorderRadius.circular(8)),
      child: Text("₦$price", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildUserSection(BuildContext context, Map<String, dynamic> data) {
    return Row(
      children: [
        CircleAvatar(backgroundImage: data['userProfileUrl'] != null ? NetworkImage(data['userProfileUrl']) : null),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(data['location'] ?? 'Nigeria', style: const TextStyle(color: textSub, fontSize: 12)),
        ]),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text("View Profile", style: TextStyle(color: bravelionBlue))),
      ],
    );
  }

  Widget _buildCircleBackButton(BuildContext context) {
    return IconButton(icon: const CircleAvatar(backgroundColor: Colors.black26, child: Icon(Icons.arrow_back, color: Colors.white, size: 20)), onPressed: () => Navigator.pop(context));
  }

  Widget _buildNotFound(BuildContext context) => const Center(child: Text("Post not found"));
}