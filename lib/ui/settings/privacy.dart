import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Color(0xFFF8F9FA); 
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- Header Info ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Effective: Jan 1, 2026',
                      style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your privacy is our priority.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This policy describes how Ventra collects, uses, and shares your data when you use our event discovery and social services.',
                    style: TextStyle(color: subtleText, fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildPolicySection(
                    title: '1. Information We Collect',
                    icon: Icons.data_usage_rounded,
                    details: [
                      _PolicyItem('Account Data', 'Email, encrypted password, and profile details like your bio and photo.'),
                      _PolicyItem('Transaction Data', 'Payment details processed securely via third-party providers (Stripe/PayPal).'),
                      _PolicyItem('Activity Data', 'Events saved, bookings, searches, and in-app interactions.'),
                      _PolicyItem('Location Data', 'Precise location for nearby event discovery (can be disabled).'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPolicySection(
                    title: '2. How We Use Data',
                    icon: Icons.visibility_outlined,
                    details: [
                      _PolicyItem('Service Provision', 'Processing tickets and managing your event social feed.'),
                      _PolicyItem('Personalization', 'Tailoring event recommendations to your interests.'),
                      _PolicyItem('Security', 'Fraud prevention and user authentication.'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPolicySection(
                    title: '3. Sharing and Disclosure',
                    icon: Icons.share_outlined,
                    details: [
                      _PolicyItem('Event Organizers', 'Name and ticket type are shared for check-in purposes.'),
                      _PolicyItem('Public Profile', 'Your username and bio are visible to other Ventra users.'),
                    ],
                  ),
                  
                  // --- Contact Footer ---
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.mail_outline_rounded, color: primaryColor, size: 30),
                        const SizedBox(height: 12),
                        const Text(
                          'Have questions?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Contact us at support@ventra.app',
                          style: TextStyle(color: subtleText, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required IconData icon,
    required List<_PolicyItem> details,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...details.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(color: subtleText, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _PolicyItem {
  final String label;
  final String description;
  _PolicyItem(this.label, this.description);
}