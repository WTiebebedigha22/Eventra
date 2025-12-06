import 'package:flutter/material.dart';
import 'package:ventra/features/profile/editprofile.dart';
import 'package:ventra/ui/auth/login.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: <Widget>[
          // --- Section 1: Account Management ---
          _SettingsSection(
            title: 'Account Management',
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile Information',
                subtitle: 'Name, Bio, Location',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                ),
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Security & Password',
                subtitle: 'Update password and security settings',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.credit_card_outlined,
                title: 'Payment Methods',
                subtitle: 'Manage cards and billing',
                onTap: () {},
              ),
            ],
          ),

          const Divider(height: 1),

          // --- Section 2: Preferences & Privacy ---
          _SettingsSection(
            title: 'Preferences & Privacy',
            children: [
              _SettingsSwitch(
                icon: Icons.visibility_off_outlined,
                title: 'Private Account',
                subtitle: 'Keep your listings hidden from public search',
                initialValue: false, // Initial state
                onChanged: (value) {
                  // Handle privacy setting change
                },
              ),
              _SettingsSwitch(
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle: 'Receive alerts for messages and updates',
                initialValue: true,
                onChanged: (value) {
                  // Handle notification setting change
                },
              ),
              _SettingsTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English (US)',
                onTap: () {},
              ),
            ],
          ),

          const Divider(height: 1),

          // --- Section 3: Support & Legal ---
          _SettingsSection(
            title: 'Support & Legal',
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.policy_outlined,
                title: 'Terms of Service',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About Ventra App',
                subtitle: 'Version 1.2.0',
                onTap: () {},
              ),
            ],
          ),

          const Divider(height: 1),
          const SizedBox(height: 20),

          // --- Section 4: Critical Actions ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Logout Button
                ElevatedButton(
                  onPressed: () {
                    // 1. **Clear Session Data (IMPORTANT):**
                    // This step depends on your authentication method (e.g., Firebase, JWT, custom backend).
                    // You must clear the stored authentication token or user ID here.

                    // Example using SharedPreferences/shared_preferences:
                    // final prefs = await SharedPreferences.getInstance();
                    // await prefs.remove('auth_token');

                    // Example using Firebase:
                    // await FirebaseAuth.instance.signOut();

                    // 2. **Navigate to the Login Page:**
                    // This command pushes the LoginScreen onto the stack and removes all
                    // previous routes, making the LoginScreen the new root of the navigation.
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        // Replace LoginScreen() with the actual constructor for your login page widget
                        builder: (context) => LoginPage(),
                      ),
                      (Route<dynamic> route) =>
                          false, // Predicate returns false, removing all routes below the new one
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: theme.cardColor,
                    foregroundColor: theme.textTheme.titleLarge?.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 10),

                // Delete Account Button
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// Helper Widget for a group of settings
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

// Helper Widget for a single actionable setting (non-switch)
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for a setting with a toggle switch
class _SettingsSwitch extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_SettingsSwitch> createState() => _SettingsSwitchState();
}

class _SettingsSwitchState extends State<_SettingsSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _toggleSwitch(bool newValue) {
    setState(() {
      _value = newValue;
    });
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blueColor = const Color(0xFF007bff); // Ventra Blue

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(widget.icon, size: 24, color: theme.iconTheme.color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                Text(widget.subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: _value,
            onChanged: _toggleSwitch,
            activeTrackColor: blueColor.withOpacity(0.5),
            activeColor: blueColor,
          ),
        ],
      ),
    );
  }
}
