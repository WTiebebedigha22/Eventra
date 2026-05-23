import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../app/app_theme.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color primaryColor = Color(0xFF6C63FF);

  final List<Map<String, dynamic>> settingGroups = const [
    {
      'title': 'Account',
      'items': [
        {
          'title': 'Edit Profile',
          'icon': Icons.person_outline,
          'route': '/edit',
          'description': 'Update your personal information'
        },
        {
          'title': 'Security',
          'icon': Icons.security_outlined,
          'route': '/settings/security',
          'description': 'Password and security settings'
        },
        {
          'title': 'Activity',
          'icon': Icons.timeline,
          'route': '/settings/activity',
          'description': 'View your activity log'
        },
      ],
    },
    {
      'title': 'Content & Display',
      'items': [
        {
          'title': 'Notifications',
          'icon': Icons.notifications_none,
          'route': '/settings/notifications',
          'description': 'Manage notification preferences'
        },
        {
          'title': 'Theme',
          'icon': Icons.dark_mode_outlined,
          'route': '/settings/theme',
          'description': 'Choose app theme'
        },
        {
          'title': 'Language',
          'icon': Icons.language_outlined,
          'route': '/settings/language',
          'description': 'Select your preferred language'
        },
      ],
    },
    {
      'title': 'Support & About',
      'items': [
        {
          'title': 'Help Center',
          'icon': Icons.help_outline,
          'action': 'help',
          'description': 'Get help and support'
        },
        {
          'title': 'Privacy Policy',
          'icon': Icons.verified_user_outlined,
          'action': 'privacy',
          'description': 'Read our privacy policy'
        },
        {
          'title': 'Terms of Service',
          'icon': Icons.description_outlined,
          'action': 'terms',
          'description': 'Terms and conditions'
        },
        {
          'title': 'About Eventra',
          'icon': Icons.info_outline,
          'action': 'about',
          'description': 'App version and credits'
        },
      ],
    },
    {
      'title': 'Danger Zone',
      'items': [
        {
          'title': 'Log Out',
          'icon': Icons.logout,
          'action': 'logout',
          'isDanger': true,
          'description': 'Sign out of your account'
        },
        {
          'title': 'Delete Account',
          'icon': Icons.delete_forever_outlined,
          'action': 'delete',
          'isDanger': true,
          'description': 'Permanently delete your account'
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = settingGroups
        .map((group) {
          final filteredItems = (group['items'] as List).where((item) {
            return item['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
          return {
            ...group,
            'items': filteredItems,
          };
        })
        .where((group) => (group['items'] as List).isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeaderCard(),
            _buildSearchBar(),
            filteredGroups.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            "No settings found",
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = "";
                                _searchController.clear();
                              });
                            },
                            child: const Text("Clear Search"),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildGroup(context, filteredGroups[index]),
                      childCount: filteredGroups.length,
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Settings',
        style: AppTextStyles.headlineMedium,
      ),
    );
  }

  Widget _buildHeaderCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.accentPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Preferences',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize your app experience',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyLarge,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Search settings...",
              hintStyle: AppTextStyles.bodyMedium,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentPurple),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = "";
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(BuildContext context, Map<String, dynamic> group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Text(
              group['title'].toString().toUpperCase(),
              style: AppTextStyles.labelSmall,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              children: (group['items'] as List).asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    _buildTile(context, item),
                    if (index != (group['items'] as List).length - 1)
                      const Divider(height: 1, indent: 72, color: AppColors.borderDefault),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, Map<String, dynamic> item) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bool isDanger = item['isDanger'] ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDanger ? AppColors.error.withOpacity(0.12) : AppColors.accentPurple.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          item['icon'],
          color: isDanger ? AppColors.error : AppColors.accentPurple,
          size: 22,
        ),
      ),
      title: Text(
        item['title'],
        style: AppTextStyles.titleMedium.copyWith(
          color: isDanger ? AppColors.error : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: item['description'] != null
          ? Text(
              item['description'],
              style: AppTextStyles.bodySmall,
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDanger ? AppColors.error : AppColors.textSecondary,
      ),
      onTap: () {
        if (item['route'] != null) {
          context.push(item['route']);
        } else if (item['action'] == 'logout') {
          _confirmDialog(
            context,
            "Logout",
            "Are you sure you want to logout?",
            () async {
              await auth.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          );
        } else if (item['action'] == 'delete') {
          _confirmDialog(
            context,
            "Delete Account",
            "This action cannot be undone. All your data will be permanently deleted.",
            () {
              _showDeleteAccountConfirmation(context, auth);
            },
            isDanger: true,
          );
        } else if (item['action'] == 'help') {
          _launchURL('https://eventra.com/help');
        } else if (item['action'] == 'privacy') {
          _launchURL('https://eventra.com/privacy');
        } else if (item['action'] == 'terms') {
          _launchURL('https://eventra.com/terms');
        } else if (item['action'] == 'about') {
          _showAboutDialog(context);
        }
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Eventra',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(Icons.event, size: 40, color: primaryColor),
        applicationLegalese: '© 2024 Eventra Inc. All rights reserved.',
        children: [
          const SizedBox(height: 16),
          const Text('Eventra is your go-to platform for discovering and booking amazing events.'),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, AuthProvider auth) {
    final TextEditingController passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password to confirm account deletion.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion feature coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _confirmDialog(BuildContext context, String title, String text, VoidCallback onConfirm, {bool isDanger = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: AppTextStyles.headlineSmall),
        content: Text(text, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: AppTextStyles.labelLarge),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppColors.error : AppColors.accentPurple,
              minimumSize: const Size(100, 45),
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}