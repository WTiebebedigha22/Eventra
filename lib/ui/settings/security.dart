import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/security_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final SecurityService _service = SecurityService();

  static const Color primaryColor = Color(0xFF3E5992);
  static const Color scaffoldBg = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color subTextColor = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Security',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _service.getSettings(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final twoFactor = data['twoFactorEnabled'] ?? false;

          return ListView(
            children: [
              _buildSectionHeader("Account Security"),

              _buildSecurityTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Send reset email',
                onTap: () {
                  _service.sendPasswordReset();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Reset email sent")),
                  );
                },
              ),

              _buildSecurityTile(
                icon: Icons.verified_user_outlined,
                title: 'Two-Factor Authentication',
                subtitle: 'Extra login security',
                trailing: Switch(
                  value: twoFactor,
                  activeColor: primaryColor,
                  onChanged: (val) async {
                    HapticFeedback.lightImpact();
                    await _service.updateSettings({
                      'twoFactorEnabled': val,
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              _buildSectionHeader("Device Management"),

              _buildSecurityTile(
                icon: Icons.devices_rounded,
                title: 'Logged In Devices',
                subtitle: 'View active sessions',
                onTap: () {
                  // later: device list screen
                },
              ),

              _buildSecurityTile(
                icon: Icons.history_rounded,
                title: 'Security Activity',
                subtitle: 'Login history',
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: subTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}