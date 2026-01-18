import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Color(0xFFF8F9FA); // Slightly off-white for depth
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Help Center',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    "How can we help you?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search help articles...",
                      prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                      filled: true,
                      fillColor: backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                "SUPPORT OPTIONS",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtleText, letterSpacing: 1.2),
              ),
            ),

            // --- Support Cards Group ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildHelpTile(
                    icon: Icons.contact_support_outlined,
                    title: 'Contact Us',
                    subtitle: 'Chat with our support team',
                    onTap: () {},
                    showDivider: true,
                  ),
                  _buildHelpTile(
                    icon: Icons.question_answer_outlined,
                    title: 'FAQ',
                    subtitle: 'Find quick answers to common questions',
                    onTap: () {},
                    showDivider: true,
                  ),
                  _buildHelpTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a Problem',
                    subtitle: 'Let us know if something isn\'t working',
                    onTap: () {},
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 12),
              child: Text(
                "LEGAL & POLICIES",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtleText, letterSpacing: 1.2),
              ),
            ),

            // --- Privacy Group ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildHelpTile(
                icon: Icons.verified_user_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () {},
                showDivider: false,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: subtleText, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
        ),
        if (showDivider)
          Divider(indent: 70, endIndent: 20, height: 1, color: Colors.grey[100]),
      ],
    );
  }
}