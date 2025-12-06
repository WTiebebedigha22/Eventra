import 'package:flutter/material.dart';
import 'package:ventra/UI/auth/Profile/accountsettings.dart';
import 'package:ventra/UI/auth/Profile/analyticspage.dart';
import 'package:ventra/UI/auth/Profile/editprofile.dart';
import 'package:url_launcher/url_launcher.dart'; // REQUIRED for launching phone/email apps

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile',
      debugShowCheckedModeBanner: false,

      // Light Theme Setup
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        cardColor: const Color(0xFFF5F5F5), // Light grey for cards/buttons
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          toolbarTextStyle: TextStyle(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black),
        ),
      ),

      // Dark Theme Setup
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF1E1E1E), // Darker grey for card backgrounds
        appBarTheme: const AppBarTheme(
          color: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          toolbarTextStyle: TextStyle(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),

      // Set the theme mode to system to enable auto-switching
      themeMode: ThemeMode.system,

      home: const ProfilePage(),
    );
  }
}

// --- Ventra Hybrid Profile Page Implementation ---

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // AppBar is configured in MyApp to be dynamic
      appBar: AppBar(
        title: Text('Profile', style: theme.appBarTheme.titleTextStyle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                  context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsPage(),
                    ),
                );},
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return const Column(
      children: [
        _ProfileHeader(),
        Divider(height: 1, thickness: 0.5),
        Expanded(child: _ContentGrid()),
      ],
    );
  }
}

class _ContactHandler {
  final BuildContext context;
  final String phoneNumber = '+2348012345678';
  final String emailAddress = 'harmony.events@ventra.com';

  _ContactHandler(this.context);

  Future<void> _launchUrl(Uri url, String fallbackMessage) async {
    if (!await launchUrl(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fallbackMessage)),
        );
      }
    }
  }

  void showContactOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Contact Harmony Events Co.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              
              // 1. Ventra Chat (Placeholder for internal navigation)
              _buildContactTile(
                icon: Icons.chat_bubble_outline,
                title: 'Message via Ventra Chat',
                subtitle: 'Send a private message now',
                onTap: () {
                  Navigator.pop(modalContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigating to Chat...')),
                  );
                },
              ),
              
              // 2. Phone Call (Launches native dialer)
              _buildContactTile(
                icon: Icons.phone_outlined,
                title: 'Call Seller',
                subtitle: phoneNumber,
                onTap: () {
                  Navigator.pop(modalContext);
                  _launchUrl(Uri(scheme: 'tel', path: phoneNumber), 'Could not open phone app.');
                },
              ),
              
              // 3. Email (Launches native email app)
              _buildContactTile(
                icon: Icons.email_outlined,
                title: 'Send Email',
                subtitle: emailAddress,
                onTap: () {
                  Navigator.pop(modalContext);
                  _launchUrl(
                    Uri(
                      scheme: 'mailto',
                      path: emailAddress,
                      queryParameters: {'subject': 'Inquiry from Ventra Profile'},
                    ),
                    'Could not open email app.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 30, color: Theme.of(context).textTheme.titleLarge?.color),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final contactHandler = _ContactHandler(context); // Instantiate the handler

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Profile Picture
              CircleAvatar(
                radius: 40,
                backgroundColor: isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[300],
                child: Icon(
                  Icons.business_center,
                  size: 40,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const <Widget>[
                    _StatColumn(count: '42', label: 'Listings'),
                    _StatColumn(count: '2.5K', label: 'Followers'),
                    _StatColumn(count: '15', label: 'Following'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                'Harmony Events Co.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(width: 8),
              // Verified Badge
              const Tooltip(
                message: 'Ventra Verified Business',
                child: Icon(Icons.verified, color: Colors.blue, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Lagos-based professional event planners specializing in weddings, corporate functions, and private parties. Delivering memorable experiences since 2018.',
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 16),

          // Row 4: Action Buttons (Jiji Focus)
          Row(
            children: <Widget>[
              // Primary Contact Button (UPDATED onPressed)
              _ActionButton(
                label: 'Contact Seller',
                icon: Icons.chat_bubble_outline,
                color: const Color(0xFF007bff), // Ventra Blue
                isPrimary: true,
                onPressed: contactHandler.showContactOptions, // CALLS THE MODAL
              ),
              const SizedBox(width: 8),
              // Analytics/Promote Placeholder
              _ActionButton(
                label: 'Analytics',
                icon: Icons.show_chart,
                color: isDarkMode ? theme.cardColor : Colors.grey[200]!,
                textColor: isDarkMode ? Colors.white : Colors.black87,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Edit/Settings Button (UPDATED onPressed)
              _ActionButton(
                label: 'Edit Profile',
                icon: Icons.edit_outlined,
                color: isDarkMode ? theme.cardColor : Colors.grey[200]!,
                textColor: isDarkMode ? Colors.white : Colors.black87,
                onPressed: () {
                  // Navigate to the EditProfileScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(), // Added const for consistency
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper Widget for the Stats (Unchanged)
class _StatColumn extends StatelessWidget {
  final String count;
  final String label;

  const _StatColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

// Helper Widget for the Action Buttons (Unchanged)
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isPrimary ? color : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? color : Theme.of(context).cardColor,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: isPrimary ? textColor : textColor),
                if (label.isNotEmpty) const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isPrimary ? textColor : textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Content Grid (Instagram Style) (Unchanged) ---
class _ContentGrid extends StatelessWidget {
  const _ContentGrid();

  // Dummy data for the grid items
  final List<Map<String, dynamic>> posts = const [
    {'type': 'photo', 'count': 1, 'color': Color(0xFFE57373)},
    {'type': 'video', 'count': 1, 'color': Color(0xFF64B5F6)},
    {'type': 'multi', 'count': 4, 'color': Color(0xFF81C784)},
    {'type': 'photo', 'count': 1, 'color': Color(0xFFFFB74D)},
    {'type': 'video', 'count': 1, 'color': Color(0xFFBA68C8)},
    {'type': 'multi', 'count': 7, 'color': Color(0xFF4DB6AC)},
    {'type': 'photo', 'count': 1, 'color': Color(0xFFE57373)},
    {'type': 'multi', 'count': 3, 'color': Color(0xFF64B5F6)},
    {'type': 'video', 'count': 1, 'color': Color(0xFFFFB74D)},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _GridItem(post: posts[index]);
      },
    );
  }
}

// Helper Widget for a single grid item (Unchanged)
class _GridItem extends StatelessWidget {
  final Map<String, dynamic> post;

  const _GridItem({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    IconData icon;
    String countText = '';

    // Determine the icon and count text based on post type
    if (post['type'] == 'video') {
      icon = Icons.videocam;
    } else if (post['type'] == 'multi') {
      icon = Icons.layers_outlined;
      countText = '${post['count']}';
    } else {
      icon = Icons.camera_alt_outlined;
    }

    // Grid item container acts as the visual placeholder
    return Container(
      color: isDarkMode
          ? post['color'].withOpacity(0.3)
          : post['color'].withOpacity(0.5),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(icon, size: 40, color: Colors.white.withOpacity(0.7)),
          ),
          // Top Right Badge for Video/Multi-photo
          if (post['type'] != 'photo')
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 12),
                    if (post['type'] == 'multi')
                      Text(
                        ' $countText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

