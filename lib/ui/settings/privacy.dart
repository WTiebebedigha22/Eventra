import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818);
  static const Color textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('Privacy Policy', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: textColor),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Effective Date: January 1, 2026',
              style: TextStyle(color: primaryPink, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              'This Privacy Policy describes how Ventra collects, uses, and shares information in connection with your use of our event discovery, ticketing, and social networking services.',
              style: TextStyle(color: textColor.withOpacity(0.8), height: 1.5),
            ),
            const SizedBox(height: 25),
            
            // --- SECTION 1: Information We Collect ---
            Text(
              '1. Information We Collect',
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            _buildPrivacyDetail(
              title: 'A. Account Data',
              content: 'When you create an account, we collect your **email address**, password (encrypted), and optional **profile information** (username, bio, profile photo).',
            ),
            _buildPrivacyDetail(
              title: 'B. Transaction Data',
              content: 'If you purchase tickets, we collect **payment details** (processed securely by a third-party vendor), **billing address**, and **event booking history**.',
            ),
            _buildPrivacyDetail(
              title: 'C. Activity and Usage Data',
              content: 'We log information about how you use the app, including **events saved** (likes), **events attended**, **searches performed**, and your **in-app chat messages** (for transmission only).',
            ),
             _buildPrivacyDetail(
              title: 'D. Location Data',
              content: 'With your permission, we collect your **precise location** to recommend nearby events and customize the explore feed. This feature can be disabled in your device settings.',
            ),
            const SizedBox(height: 25),

            // --- SECTION 2: How We Use Your Information ---
            Text(
              '2. How We Use Your Information',
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            _buildPrivacyDetail(
              title: 'Service Provision',
              content: 'To process ticket purchases, manage your bookings, and provide access to features like event chat and profile management.',
            ),
            _buildPrivacyDetail(
              title: 'Personalization and Discovery',
              content: 'To personalize your event feed, recommend events based on your activity, and send notifications about events you might like.',
            ),
            _buildPrivacyDetail(
              title: 'Security and Fraud Prevention',
              content: 'To authenticate users, prevent fraudulent ticketing activity, and ensure the security of our platform.',
            ),
            const SizedBox(height: 25),

            // --- SECTION 3: Sharing and Disclosure ---
            Text(
              '3. Sharing and Disclosure',
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
             _buildPrivacyDetail(
              title: 'Event Organizers',
              content: 'We share necessary ticketing information (e.g., your name, ticket type) with the **organizers** of the events you book for entry and management.',
            ),
            _buildPrivacyDetail(
              title: 'Payment Processors',
              content: 'We share payment details with secure **third-party payment processors** (Stripe, PayPal, etc.) to complete your ticket transactions.',
            ),
            _buildPrivacyDetail(
              title: 'Public Profile Information',
              content: 'Your username, profile photo, and bio are **publicly visible** to other users on the platform.',
            ),
            const SizedBox(height: 30),
            
            // --- Contact Information ---
             Text(
              '4. Contact Us',
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'If you have any questions about this Privacy Policy, please contact us at support@ventra.app or visit the Help section in the app settings.',
              style: TextStyle(color: textColor.withOpacity(0.8), height: 1.5),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  
  // Helper widget to style privacy bullet points
  Widget _buildPrivacyDetail({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title',
            style: const TextStyle(color: primaryPink, fontWeight: FontWeight.w600),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4),
            child: Text(
              content,
              style: TextStyle(color: textColor.withOpacity(0.7), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}