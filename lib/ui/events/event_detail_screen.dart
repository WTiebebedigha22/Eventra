import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final PageController _imagePageController = PageController();

  // Theme Colors
  static const Color bravelionBlue = Colors.deepPurpleAccent;
  static const Color jijiGreen = Color(0xFF3BA73A);
  static const Color textMain = Color(0xFF1C1E21);
  static const Color textSub = Color(0xFF65676B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Fixed Bottom Navigation for high-conversion actions
      bottomNavigationBar: _buildBottomActionPanel(context),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('events').doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading event"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: bravelionBlue));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Event not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          List<String> images = [];
          if (data['mediaUrls'] != null) {
            images = List<String>.from(data['mediaUrls']);
          } else if (data['imageUrl'] != null) {
            images = [data['imageUrl']];
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Immersive Header
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
                      if (images.length > 1)
                        Positioned(bottom: 20, right: 20, child: _buildCountBadge(images.length)),
                    ],
                  ),
                ),
              ),

              // Content Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserSection(context, data),
                      const SizedBox(height: 24),
                      Text(
                        data['title'] ?? 'Untitled Event',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 12),
                      
                      // Metadata: Date & Location
                      _buildMetaRow(Icons.calendar_month_outlined, "April 24th, 2026 • 6:00 PM"),
                      const SizedBox(height: 8),
                      _buildMetaRow(Icons.location_on_outlined, data['location'] ?? 'Lagos, Nigeria'),
                      
                      const SizedBox(height: 25),
                      const Text("About this Event", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        data['description'] ?? 'No description provided.',
                        style: const TextStyle(fontSize: 15, color: textSub, height: 1.6),
                      ),
                      const SizedBox(height: 30),
                      const Divider(),
                    ],
                  ),
                ),
              ),

              // Recommendations Section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text("Recommended Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('events').limit(6).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 20),
                        itemCount: snap.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snap.data!.docs[index];
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

  // --- UI COMPONENTS ---

  Widget _buildBottomActionPanel(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 20, right: 20, top: 15
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuickSuggestions(),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: textMain),
                  onPressed: () => _sendMessage(context, "I'm interested!"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bravelionBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.push('/event/${widget.eventId}/purchase-tickets'),
                  child: const Text("PURCHASE TICKETS", 
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = ["Still available?", "Sitting capacity?", "Final price?", "Starting time?"];
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _sendMessage(context, suggestions[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(20)
            ),
            alignment: Alignment.center,
            child: Text(suggestions[i], style: const TextStyle(fontSize: 11, color: textSub)),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) return Container(color: Colors.grey[200]);
    return PageView.builder(
      controller: _imagePageController,
      itemCount: images.length,
      itemBuilder: (context, index) => Image.network(images[index], fit: BoxFit.cover),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: bravelionBlue),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMain)),
      ],
    );
  }

  Widget _buildPriceBadge(dynamic price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: jijiGreen, borderRadius: BorderRadius.circular(10)),
      child: Text("₦$price", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildUserSection(BuildContext context, Map<String, dynamic> data) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: data['userProfileUrl'] != null ? NetworkImage(data['userProfileUrl']) : null,
          backgroundColor: Colors.grey[200],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['username'] ?? 'Organizer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Text("Official Partner", style: TextStyle(color: textSub, fontSize: 12)),
          ],
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: () {}, 
          style: OutlinedButton.styleFrom(side: const BorderSide(color: bravelionBlue), shape: const StadiumBorder()),
          child: const Text("Follow", style: TextStyle(color: bravelionBlue, fontSize: 13)),
        )
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> data) {
    final thumb = (data['mediaUrls'] as List?)?.first ?? data['imageUrl'] ?? '';
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(thumb, height: 110, width: 170, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[100])),
          ),
          const SizedBox(height: 10),
          Text(data['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("₦${data['price']}", style: const TextStyle(color: jijiGreen, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() => const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black26, Colors.transparent, Colors.black45])));
  
  Widget _buildCountBadge(int count) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.image, color: Colors.white, size: 12), const SizedBox(width: 4), Text("$count", style: const TextStyle(color: Colors.white, fontSize: 11))]));

  Widget _buildCircleBackButton(BuildContext context) => Padding(padding: const EdgeInsets.all(8.0), child: CircleAvatar(backgroundColor: Colors.black26, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18), onPressed: () => context.pop())));

  void _sendMessage(BuildContext context, String msg) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sending: $msg"), behavior: SnackBarBehavior.floating));
  }
}