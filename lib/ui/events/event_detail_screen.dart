import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final PageController _imagePageController = PageController();

  static const Color bravelionBlue = Colors.deepPurpleAccent;
  static const Color jijiGreen = Color(0xFF3BA73A);
  static const Color textMain = Color(0xFF1C1E21);
  static const Color textSub = Color(0xFF65676B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomActionPanel(context),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading event"));
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: bravelionBlue),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          /// ✅ MEDIA HANDLING (IMAGE + VIDEO)
          List<Map<String, dynamic>> mediaList = [];

          if (data['media'] != null) {
            mediaList = List<Map<String, dynamic>>.from(data['media']);
          } else if (data['mediaUrls'] != null) {
            mediaList = List<String>.from(data['mediaUrls'])
                .map((url) => {
                      'url': url,
                      'type': url.contains('.mp4') ? 'video' : 'image',
                    })
                .toList();
          } else if (data['imageUrl'] != null) {
            mediaList = [
              {'url': data['imageUrl'], 'type': 'image'}
            ];
          }

          return CustomScrollView(
            slivers: [
              /// ─── HEADER ─────────────────────────────
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: bravelionBlue,
                leading: _buildCircleBackButton(context),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaCarousel(mediaList),
                      _buildGradientOverlay(),

                      if (mediaList.length > 1)
                        Positioned(
                          bottom: 60,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _imagePageController,
                              count: mediaList.length,
                              effect: const ScrollingDotsEffect(
                                dotWidth: 8,
                                dotHeight: 8,
                                activeDotColor: Colors.white,
                                dotColor: Colors.white54,
                              ),
                            ),
                          ),
                        ),

                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: _buildPriceBadge(data['price']),
                      ),

                      if (mediaList.length > 1)
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: _buildCountBadge(mediaList.length),
                        ),
                    ],
                  ),
                ),
              ),

              /// ─── CONTENT ─────────────────────────────
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
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildMetaRow(Icons.calendar_month, "April 24 • 6PM"),
                      const SizedBox(height: 8),
                      _buildMetaRow(
                          Icons.location_on, data['location'] ?? "Lagos"),

                      const SizedBox(height: 25),

                      const Text("About",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 10),

                      Text(
                        data['description'] ?? "No description",
                        style: const TextStyle(
                          color: textSub,
                          height: 1.6,
                        ),
                      ),
                    ],
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

  /// ─── MEDIA CAROUSEL ─────────────────────────────
  Widget _buildMediaCarousel(List<Map<String, dynamic>> mediaList) {
    if (mediaList.isEmpty) {
      return Container(color: Colors.grey[200]);
    }

    return PageView.builder(
      controller: _imagePageController,
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final item = mediaList[index];

        if (item['type'] == 'video') {
          return _VideoPlayerWidget(videoUrl: item['url']);
        }

        return Image.network(
          item['url'],
          fit: BoxFit.cover,
        );
      },
    );
  }

  Widget _buildGradientOverlay() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black26, Colors.transparent, Colors.black45],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );

  // ✅ FIXED: correct full nested path
  Widget _buildBottomActionPanel(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 20,
        right: 20,
        top: 15,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: bravelionBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => context.push(
                '/home/event/${widget.eventId}/purchase-tickets', // ✅ Fixed path
              ),
              child: const Text(
                "PURCHASE TICKETS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: bravelionBlue),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildPriceBadge(dynamic price) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: jijiGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text("₦$price",
          style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text("$count",
          style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildUserSection(BuildContext context, Map<String, dynamic> data) {
    return Row(
      children: [
        const CircleAvatar(),
        const SizedBox(width: 10),
        Text(data['username'] ?? "Organizer"),
      ],
    );
  }

  Widget _buildCircleBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => context.pop(),
    );
  }
}

/// ─── VIDEO PLAYER WIDGET ─────────────────────────────
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _toggle,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isPlaying)
            const Icon(Icons.play_circle, size: 60, color: Colors.white),
        ],
      ),
    );
  }
}