import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventra/ui/components/event_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Matches HomeScreen background
      body: CustomScrollView(
        slivers: [
          // Elegant Header
          const SliverAppBar(
            backgroundColor: Color(0xFF0F0F0F),
            floating: true,
            title: Text(
              "Ventra",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: -1,
              ),
            ),
            centerTitle: false,
          ),

          // Real-time Feed
          StreamBuilder<QuerySnapshot>(
            // Change 'events' to 'posts' if that is your collection name
            stream: FirebaseFirestore.instance
                .collection('events')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SliverFillRemaining(
                  child: Center(child: Text("Error loading feed", style: TextStyle(color: Colors.white))),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFE91E63))),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No events found", style: TextStyle(color: Colors.white54))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      // Inject the document ID for the Like/Comment logic to work
                      data['id'] = docs[index].id;

                      return EventCard(event: data);
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}