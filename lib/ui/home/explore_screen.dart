import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventra/ui/components/event_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          // The StreamBuilder handles real-time updates, 
          // but RefreshIndicator provides a familiar UX.
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- Modern App Bar ---
            SliverAppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              floating: true,
              pinned: false,
              centerTitle: false,
              title: const Text(
                "Eventra",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -1.2,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: textColor),
                  onPressed: () {}, // Future Activity page link
                ),
                const SizedBox(width: 8),
              ],
            ),

            // --- Real-time Feed ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: _buildStateMessage(
                      Icons.error_outline_rounded,
                      "Something went wrong",
                      "We couldn't load the feed right now.",
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: primaryColor,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildStateMessage(
                      Icons.event_busy_rounded,
                      "No events yet",
                      "Be the first to create an event in your area!",
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Extra bottom padding for FAB/Nav
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        data['id'] = docs[index].id;

                        // Adding a small vertical gap between cards
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: EventCard(event: data),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper for Empty/Error States ---
  Widget _buildStateMessage(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: subtleText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}