import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with SingleTickerProviderStateMixin {
  final PageController _imagePageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isSaved = false;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color textMain = Color(0xFF1C1E21);
  static const Color textSub = Color(0xFF65676B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date TBD';
    if (date is Timestamp) {
      return DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(date.toDate());
    }
    return 'Date TBD';
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Free';
    final format = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    return format.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error);
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // Media handling
          List<Map<String, dynamic>> mediaList = [];
          if (data['media'] != null) {
            mediaList = List<Map<String, dynamic>>.from(data['media']);
          } else if (data['imageUrl'] != null) {
            mediaList = [
              {'url': data['imageUrl'], 'type': 'image'}
            ];
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                _buildHeader(mediaList, data),
                _buildContent(data),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(List<Map<String, dynamic>> mediaList, Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildMediaCarousel(mediaList),
            _buildGradientOverlay(),
            if (mediaList.length > 1)
              Positioned(
                bottom: 80,
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
              child: _buildPriceTag(data['price']),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCarousel(List<Map<String, dynamic>> mediaList) {
    if (mediaList.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return PageView.builder(
      controller: _imagePageController,
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final item = mediaList[index];
        if (item['type'] == 'video') {
          return _VideoPlayerWidget(videoUrl: item['url']);
        }
        return CachedNetworkImage(
          imageUrl: item['url'],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildPriceTag(dynamic price) {
    final isFree = price == null || price == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFree ? [successColor, successColor.withOpacity(0.8)] : [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        isFree ? 'FREE' : _formatPrice(price),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton(
          icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          onTap: () => setState(() => _isLiked = !_isLiked),
          color: _isLiked ? accentColor : Colors.white,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          onTap: () => setState(() => _isSaved = !_isSaved),
          color: _isSaved ? primaryColor : Colors.white,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.share_rounded,
          onTap: () => _showShareOptions(),
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
      onPressed: () => context.pop(),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrganizerSection(data),
            const SizedBox(height: 20),
            Text(
              data['title'] ?? 'Untitled Event',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textMain),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today_outlined, _formatDate(data['eventDate'])),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, data['location'] ?? 'Location TBD'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.people_outline, '${data['capacity'] ?? 'Unlimited'} capacity'),
            const SizedBox(height: 24),
            _buildCategoryChip(data['category']),
            const SizedBox(height: 24),
            const Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              data['description'] ?? 'No description available',
              style: const TextStyle(color: textSub, height: 1.6, fontSize: 15),
            ),
            const SizedBox(height: 32),
            _buildHostInfo(data),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizerSection(Map<String, dynamic> data) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['organizer'] ?? data['username'] ?? 'Event Organizer',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Event Organizer',
                style: TextStyle(color: textSub, fontSize: 12),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text('Follow', style: TextStyle(color: primaryColor)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: textSub))),
      ],
    );
  }

  Widget _buildCategoryChip(String? category) {
    if (category == null || category.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildHostInfo(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hosted by ${data['organizer'] ?? data['username'] ?? 'Organizer'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('Verified event organizer', style: TextStyle(fontSize: 12, color: textSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        left: 20,
        right: 20,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () => context.push('/home/event/${widget.eventId}/purchase-tickets'),
                child: const Text(
                  "GET TICKETS",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('Unable to load event details'),
          const SizedBox(height: 8),
          Text(error?.toString() ?? 'Unknown error', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareOption(Icons.chat, 'WhatsApp', () {}),
                _buildShareOption(Icons.camera_alt, 'Instagram', () {}),
                _buildShareOption(Icons.alternate_email, 'Twitter', () {}),
                _buildShareOption(Icons.link, 'Copy Link', () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _controller.initialize().then((_) {
      setState(() => _isInitialized = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_circle_filled, size: 64, color: Colors.white),
            ),
        ],
      ),
    );
  }
}