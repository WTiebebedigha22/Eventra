import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VendorCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  
  const VendorCard({super.key, required this.vendor});

  // Theme Constants
  static const Color jijiGreen = Color(0xFF3BA73A);
  static const Color accentBlue = Color(0xFF3E5992);

  @override
  Widget build(BuildContext context) {
    // Extracting data safely
    final String shopName = vendor['shopName'] ?? vendor['username'] ?? 'Official Store';
    final String? logoUrl = vendor['logoUrl'] ?? vendor['photoURL'];
    final String? bannerUrl = vendor['bannerUrl'];
    final double rating = (vendor['rating'] ?? 0.0).toDouble();
    final String location = vendor['location'] ?? 'Benin City';
    final bool isVerified = vendor['isVerified'] ?? false;

    return GestureDetector(
      onTap: () => context.push('/profile/${vendor['uid']}'),
      child: Container(
        width: 280, // Optimized for horizontal scrolling feeds
        margin: const EdgeInsets.only(right: 16, bottom: 10, top: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Banner & Logo Stack
            SizedBox(
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Shop Banner
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: bannerUrl != null
                          ? Image.network(bannerUrl, fit: BoxFit.cover)
                          : Container(color: accentBlue.withOpacity(0.1)),
                    ),
                  ),
                  // Glassmorphism Location Tag
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildLocationBadge(location),
                  ),
                  // Floating Logo
                  Positioned(
                    bottom: -20,
                    left: 20,
                    child: _buildVendorLogo(logoUrl, isVerified),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 2. Vendor Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shopName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        const Icon(Icons.verified_rounded, color: jijiGreen, size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildRatingBar(rating),
                  const SizedBox(height: 12),
                  Text(
                    vendor['description'] ?? 'No description provided.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 3. Action Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/profile/${vendor['uid']}'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("VISIT SHOP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(Icons.chat_bubble_outline_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorLogo(String? url, bool isVerified) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[100],
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null ? const Icon(Icons.storefront_rounded, color: accentBlue) : null,
      ),
    );
  }

  Widget _buildLocationBadge(String location) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.black.withOpacity(0.3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(location, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar(double rating) {
    return Row(
      children: [
        Icon(Icons.star_rounded, color: Colors.amber[700], size: 16),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Text(
          "(80+ Reviews)", // Static for UI demo, should come from data
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: jijiGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: jijiGreen, size: 20),
    );
  }
}