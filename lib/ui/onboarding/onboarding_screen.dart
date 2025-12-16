import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../ui/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final int _numPages = 3;

  double _currentPage = 0.0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() => _currentPage = _pageController.page!);
      }
    });

    // 🔁 Auto-slide every 3 seconds
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients) return;

      final nextPage = _currentPage.round() + 1;
      if (nextPage < _numPages) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Discover Your Interests',
      'description': 'Browse millions of ideas, from recipes to travel.',
      'image': 'assets/onboarding/onboarding1.jpg',
    },
    {
      'title': 'Collect and Organize',
      'description': 'Save your favorite Pins to boards for later access.',
      'image': 'assets/onboarding/onboarding2.jpg',
    },
    {
      'title': 'Join the Community',
      'description': 'Follow creators and explore personalized feeds.',
      'image': 'assets/onboarding/onboarding3.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundAnimation(_currentPage),

          PageView.builder(
            controller: _pageController,
            itemCount: _numPages,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final opacity = (1 - (_currentPage - index).abs()).clamp(0.0, 1.0);
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: opacity,
                child: _buildPageContent(
                  title: onboardingData[index]['title']!,
                  description: onboardingData[index]['description']!,
                ),
              );
            },
          ),

          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: _buildPageIndicator(),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _buildActionButton(_currentPage),
          ),
        ],
      ),
    );
  }

  // Background cross-fade + zoom animation
  Widget _buildBackgroundAnimation(double currentPage) {
    final int currentIndex = currentPage.floor();
    final int nextIndex = currentIndex + 1;
    final double scrollOffset = currentPage - currentIndex;

    final double currentOpacity = 1.0 - math.min(1.0, scrollOffset.abs());
    final double nextOpacity = math.min(1.0, scrollOffset.abs());

    return Stack(
      fit: StackFit.expand,
      children: [
        if (currentIndex < _numPages)
          _bgImage(onboardingData[currentIndex]['image']!, currentOpacity, 1.0),
        if (nextIndex < _numPages && scrollOffset > 0)
          _bgImage(onboardingData[nextIndex]['image']!, nextOpacity, 1.05),
      ],
    );
  }

  Widget _bgImage(String image, double opacity, double scale) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.25),
                BlendMode.darken,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 150),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    final int roundedPage = _currentPage.round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _numPages,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 8,
          width: i == roundedPage ? 24 : 8,
          decoration: BoxDecoration(
            color: i == roundedPage ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(double currentPage) {
    final bool isLastPage = currentPage.round() == _numPages - 1;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: isLastPage ? Colors.purple : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      onPressed: () {
        _autoSlideTimer?.cancel();
        if (isLastPage) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Text(
        isLastPage ? 'Get Started' : 'Next',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isLastPage ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
