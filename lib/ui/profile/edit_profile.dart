// ─── Edit Profile Screen ────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../core/shared_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Amara Okafor');
  final _bioController = TextEditingController(text: 'Music lover & event enthusiast 🎵');
  final _phoneController = TextEditingController(text: '+234 801 234 5678');
  final _locationController = TextEditingController(text: 'Lagos, Nigeria');
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(color: AppColors.accentPurple, strokeWidth: 2),
                  )
                : Text('Save', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accentPurple)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.purpleGradient),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('AO', style: AppTextStyles.displayMedium.copyWith(fontSize: 32)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgPrimary, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            AppTextField(label: 'Full Name', controller: _nameController, prefixIcon: Icons.person_outline),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Bio',
              controller: _bioController,
              maxLines: 3,
              hint: 'Tell the world a little about yourself...',
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Phone', controller: _phoneController, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            AppTextField(label: 'Location', controller: _locationController, prefixIcon: Icons.location_on_outlined),
            const SizedBox(height: 32),

            // Danger zone
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete Account', style: AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
                        Text('This action is irreversible', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showDeleteConfirm(context),
                    child: Text('Delete', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Delete Account?', style: AppTextStyles.headlineMedium),
        content: Text('All your data will be permanently removed.', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Delete', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Organiser Profile Screen ───────────────────────────────────────────────────

class OrganiserProfileScreen extends StatelessWidget {
  final String organiserId;
  final String name;
  final String bio;
  final double rating;
  final int eventCount;
  final int followerCount;

  const OrganiserProfileScreen({
    super.key,
    required this.organiserId,
    required this.name,
    required this.bio,
    required this.rating,
    required this.eventCount,
    required this.followerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.bgPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.purpleGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          name.substring(0, 2).toUpperCase(),
                          style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: AppTextStyles.headlineLarge.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text('Verified Organiser', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                Row(
                  children: [
                    _StatChip(label: 'Events', value: eventCount.toString()),
                    const SizedBox(width: 12),
                    _StatChip(label: 'Followers', value: '${(followerCount / 1000).toStringAsFixed(1)}K'),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Rating',
                      value: rating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      iconColor: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bio
                Text('About', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Text(bio, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 24),

                // Follow button
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(label: 'Follow', onPressed: () {}),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                SectionHeader(title: 'Upcoming Events', actionLabel: 'See all', onAction: () {}),
                const SizedBox(height: 12),

                // Mock upcoming events
                ...['Afro Beats Night Vol. 3', 'Electronic Underground', 'Jazz & Wine Evening']
                    .map((title) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: AppColors.purpleGradient),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.event, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(title, style: AppTextStyles.titleMedium),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textHint),
                            ],
                          ),
                        )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _StatChip({required this.label, required this.value, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: iconColor ?? AppColors.accentPurple),
                  const SizedBox(width: 4),
                ],
                Text(value, style: AppTextStyles.headlineSmall),
              ],
            ),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Screen ───────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _locationServices = true;
  bool _biometricLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _SettingsSection(
            title: 'Account',
            items: [
              _SettingsTile(icon: Icons.person_outline, label: 'Edit Profile', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
              _SettingsTile(icon: Icons.lock_outline, label: 'Change Password', onTap: () {}),
              _SettingsTile(icon: Icons.favorite_outline, label: 'My Interests', onTap: () {}),
            ],
          ),
          _SettingsSection(
            title: 'Notifications',
            items: [
              _SettingsSwitchTile(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              _SettingsSwitchTile(
                icon: Icons.email_outlined,
                label: 'Email Updates',
                value: _emailUpdates,
                onChanged: (v) => setState(() => _emailUpdates = v),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Privacy & Security',
            items: [
              _SettingsSwitchTile(
                icon: Icons.location_on_outlined,
                label: 'Location Services',
                value: _locationServices,
                onChanged: (v) => setState(() => _locationServices = v),
              ),
              _SettingsSwitchTile(
                icon: Icons.fingerprint_outlined,
                label: 'Biometric Login',
                value: _biometricLogin,
                onChanged: (v) => setState(() => _biometricLogin = v),
              ),
              _SettingsTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
            ],
          ),
          _SettingsSection(
            title: 'Support',
            items: [
              _SettingsTile(icon: Icons.help_outline, label: 'Help & FAQ', onTap: () {}),
              _SettingsTile(icon: Icons.chat_outlined, label: 'Contact Support', onTap: () {}),
              _SettingsTile(icon: Icons.star_outline, label: 'Rate the App', onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Sign Out',
            variant: AppButtonVariant.outlined,
            onPressed: () {},
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Eventra v1.0.0', style: AppTextStyles.bodySmall),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < items.length - 1)
                    const Divider(height: 0, indent: 52),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.accentPurple, size: 20),
      title: Text(label, style: AppTextStyles.titleMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentPurple, size: 20),
      title: Text(label, style: AppTextStyles.titleMedium),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accentPurple,
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.accentPurple.withOpacity(0.3) : AppColors.borderDefault),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ─── Booking History Screen ─────────────────────────────────────────────────────

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = [
      {'title': 'Burna Boy Live', 'date': 'Jun 14, 2025', 'seats': 'B5, B6', 'status': 'upcoming', 'price': '\$240'},
      {'title': 'Afrobeats Festival', 'date': 'May 20, 2025', 'seats': 'C3', 'status': 'attended', 'price': '\$85'},
      {'title': 'Lagos Tech Summit', 'date': 'Apr 3, 2025', 'seats': 'D7', 'status': 'attended', 'price': '\$50'},
      {'title': 'Comedy Night Out', 'date': 'Mar 15, 2025', 'seats': 'A2', 'status': 'cancelled', 'price': '\$60'},
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(title: const Text('My Bookings')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final b = bookings[i];
          final status = b['status'] as String;
          final statusColor = status == 'upcoming'
              ? AppColors.accentPurple
              : status == 'attended'
                  ? AppColors.success
                  : AppColors.error;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: status == 'cancelled'
                          ? [AppColors.bgElevated, AppColors.bgElevated]
                          : AppColors.purpleGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    status == 'cancelled' ? Icons.event_busy_outlined : Icons.confirmation_number_outlined,
                    color: status == 'cancelled' ? AppColors.textHint : Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b['title']!, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text('${b['date']} · ${b['seats']}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(b['price']!, style: AppTextStyles.titleMedium.copyWith(color: AppColors.accentOrange)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.labelSmall.copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Leave a Review Screen ──────────────────────────────────────────────────────

class LeaveReviewScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const LeaveReviewScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  final List<String> _tags = ['Great vibe', 'Well organised', 'Amazing performers', 'Good value', 'Would go again'];
  final Set<String> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(title: const Text('Leave a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How was ${widget.eventTitle}?', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 24),

            // Star rating
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: i < _rating ? AppColors.warning : AppColors.textHint,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _rating == 0 ? 'Tap to rate' : ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'][_rating],
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _rating > 0 ? AppColors.warning : AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text('Quick tags', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return CategoryChip(
                  label: tag,
                  isSelected: isSelected,
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            AppTextField(
              label: 'Write your review',
              hint: 'Share your experience in detail...',
              controller: _reviewController,
              maxLines: 5,
            ),
            const SizedBox(height: 32),

            GradientButton(
              label: 'Submit Review',
              onPressed: _rating > 0 ? () => Navigator.pop(context) : null,
              colors: _rating > 0 ? AppColors.purpleGradient : [AppColors.bgElevated, AppColors.bgElevated],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Social Share Sheet ─────────────────────────────────────────────────────────

class SocialShareSheet extends StatelessWidget {
  final String eventTitle;
  final String eventDate;
  final String eventVenue;

  const SocialShareSheet({
    super.key,
    required this.eventTitle,
    required this.eventDate,
    required this.eventVenue,
  });

  static void show(BuildContext context, {
    required String eventTitle,
    required String eventDate,
    required String eventVenue,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SocialShareSheet(
        eventTitle: eventTitle,
        eventDate: eventDate,
        eventVenue: eventVenue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platforms = [
      _SharePlatform(label: 'WhatsApp', icon: Icons.chat_outlined, color: const Color(0xFF25D366)),
      _SharePlatform(label: 'Instagram', icon: Icons.camera_alt_outlined, color: const Color(0xFFE1306C)),
      _SharePlatform(label: 'Twitter', icon: Icons.alternate_email, color: const Color(0xFF1DA1F2)),
      _SharePlatform(label: 'Copy Link', icon: Icons.link_outlined, color: AppColors.accentPurple),
      _SharePlatform(label: 'More', icon: Icons.more_horiz, color: AppColors.textHint),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text('Share Event', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text(eventTitle, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 24),

          // Preview card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.purpleGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eventTitle, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('$eventDate · $eventVenue', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Share platforms
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: platforms.map((p) => _SharePlatformButton(platform: p)).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SharePlatform {
  final String label;
  final IconData icon;
  final Color color;

  const _SharePlatform({required this.label, required this.icon, required this.color});
}

class _SharePlatformButton extends StatelessWidget {
  final _SharePlatform platform;

  const _SharePlatformButton({required this.platform});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: platform.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(platform.icon, color: platform.color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(platform.label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}