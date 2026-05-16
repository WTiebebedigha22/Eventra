import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../core/shared_widget.dart';

class InterestPickerScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const InterestPickerScreen({super.key, required this.onComplete});

  @override
  State<InterestPickerScreen> createState() => _InterestPickerScreenState();
}

class _Interest {
  final String label;
  final String emoji;
  final Color color;

  const _Interest({required this.label, required this.emoji, required this.color});
}

class _InterestPickerScreenState extends State<InterestPickerScreen>
    with TickerProviderStateMixin {
  final Set<String> _selected = {};
  late List<AnimationController> _animations;

  final List<_Interest> _interests = const [
    _Interest(label: 'Music', emoji: '🎵', color: Color(0xFF7C4DFF)),
    _Interest(label: 'Sports', emoji: '⚽', color: Color(0xFF4CAF50)),
    _Interest(label: 'Art', emoji: '🎨', color: Color(0xFFFF6B35)),
    _Interest(label: 'Tech', emoji: '💻', color: Color(0xFF2196F3)),
    _Interest(label: 'Comedy', emoji: '😂', color: Color(0xFFFFC107)),
    _Interest(label: 'Food', emoji: '🍽️', color: Color(0xFFE91E63)),
    _Interest(label: 'Film', emoji: '🎬', color: Color(0xFF9C27B0)),
    _Interest(label: 'Dance', emoji: '💃', color: Color(0xFFFF5722)),
    _Interest(label: 'Theatre', emoji: '🎭', color: Color(0xFF00BCD4)),
    _Interest(label: 'Fashion', emoji: '👗', color: Color(0xFFF06292)),
    _Interest(label: 'Gaming', emoji: '🎮', color: Color(0xFF3F51B5)),
    _Interest(label: 'Wellness', emoji: '🧘', color: Color(0xFF8BC34A)),
    _Interest(label: 'Photography', emoji: '📸', color: Color(0xFF607D8B)),
    _Interest(label: 'Travel', emoji: '✈️', color: Color(0xFF00ACC1)),
    _Interest(label: 'Science', emoji: '🔬', color: Color(0xFF26C6DA)),
    _Interest(label: 'Outdoor', emoji: '🏕️', color: Color(0xFF66BB6A)),
  ];

  @override
  void initState() {
    super.initState();
    _animations = List.generate(
      _interests.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 40),
      ),
    );
    // Stagger entry animations
    for (var i = 0; i < _animations.length; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 50), () {
        if (mounted) _animations[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final a in _animations) {
      a.dispose();
    }
    super.dispose();
  }

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.2,
                colors: [
                  Color(0xFF1A0A2E),
                  Color(0xFF0F0F0F),
                ],
              ),
            ),
          ),
          // Decorative orbs
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentPurple.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentOrange.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      Row(
                        children: List.generate(
                          3,
                          (i) => Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                              height: 3,
                              decoration: BoxDecoration(
                                color: i == 2 ? AppColors.accentPurple : AppColors.borderDefault,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Text(
                        'What are you\ninto? 🎉',
                        style: AppTextStyles.displayLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pick at least 3 interests so we can personalise your event feed.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Interest grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _interests.length,
                    itemBuilder: (_, i) {
                      final interest = _interests[i];
                      final isSelected = _selected.contains(interest.label);
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animations[i],
                          curve: Curves.easeOut,
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animations[i],
                            curve: Curves.easeOut,
                          )),
                          child: _InterestChip(
                            interest: interest,
                            isSelected: isSelected,
                            onTap: () => _toggle(interest.label),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom bar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                  child: Column(
                    children: [
                      // Selection count
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _selected.isEmpty
                            ? Text(
                                'Select at least 3 interests',
                                key: const ValueKey('empty'),
                                style: AppTextStyles.bodyMedium,
                              )
                            : Text(
                                key: ValueKey(_selected.length),
                                '${_selected.length} selected — ${_selected.length >= 3 ? "good to go!" : "${3 - _selected.length} more to go"}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _selected.length >= 3
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                      GradientButton(
                        label: 'Continue',
                        onPressed: _selected.length >= 3 ? widget.onComplete : null,
                        colors: _selected.length >= 3
                            ? AppColors.purpleGradient
                            : [AppColors.bgElevated, AppColors.bgElevated],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onComplete,
                        child: Text(
                          'Skip for now',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final _Interest interest;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.interest,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? interest.color.withOpacity(0.2)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? interest.color : AppColors.borderDefault,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(interest.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(
                    interest.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? interest.color : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: interest.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}