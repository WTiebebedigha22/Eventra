import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../ui/auth/login.dart'; 

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // 1. Controller for the PageView
  final PageController _pageController = PageController();
  // 2. Total number of onboarding pages
  final int _numPages = 3; 

  // Store the current page value in a variable to avoid repeated calculations
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    // Listen to page changes and update the state variable
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Sample data for the pages
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
    // We now use _currentPage from the state
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _buildBackgroundAnimation(_currentPage),

          // 2. PageView for Swiping Content
          PageView.builder(
            controller: _pageController,
            itemCount: _numPages,
            physics: const BouncingScrollPhysics(), 
            itemBuilder: (context, index) {
              return _buildPageContent(
                title: onboardingData[index]['title']!,
                description: onboardingData[index]['description']!,
              );
            },
          ),

          // 3. Dots Indicator (Optional)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: _buildPageIndicator(),
          ),

          // 4. Action Button (Get Started/Next)
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
  
  // --- Animation Helper Widget ---

  Widget _buildBackgroundAnimation(double currentPage) {
    // Current page index (integer part of the page offset)
    final int currentIndex = currentPage.floor();
    
    // Index of the next page
    final int nextIndex = currentIndex + 1;

    // Relative offset from the start of the current page (0.0 to 1.0)
    final double scrollOffset = currentPage - currentIndex;

    // Value for the current image: 1.0 (start) to 0.0 (end of swipe)
    final double currentImageOpacity = 1.0 - math.min(1.0, scrollOffset.abs());

    // Value for the next image: 0.0 (start) to 1.0 (end of swipe)
    final double nextImageOpacity = math.min(1.0, scrollOffset.abs());

    // Scale for the current image (zooms out slightly as it fades)
    final double currentImageScale = 1.0 + (1.0 - currentImageOpacity) * 0.05; 
    
    // Scale for the next image (zooms in slightly as it appears)
    final double nextImageScale = 1.05 - (1.0 - nextImageOpacity) * 0.05; 

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Current Image (Fades out and zooms out)
        if (currentIndex < _numPages)
          _buildAnimatedImage(
            imagePath: onboardingData[currentIndex]['image']!,
            opacity: currentImageOpacity,
            scale: currentImageScale,
          ),
        
        // 2. Next Image (Fades in and zooms in), shown only during the transition
        if (nextIndex < _numPages && scrollOffset > 0)
          _buildAnimatedImage(
            imagePath: onboardingData[nextIndex]['image']!,
            opacity: nextImageOpacity,
            scale: nextImageScale,
          ),
      ],
    );
  }

  // Helper function to apply the animation properties to the image
  Widget _buildAnimatedImage({required String imagePath, required double opacity, required double scale}) {
    return Center(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              // Use the actual image path from the data map
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                // Optional: Slightly darker overlay for text readability
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // --- Page Content Widget (No changes needed) ---

  Widget _buildPageContent({required String title, required String description}) {
    // ... (content remains the same)
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          const SizedBox(height: 100), 
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 10.0, color: Colors.black, offset: Offset(0, 2))
              ]
            ),
          ),
          const SizedBox(height: 15.0),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              shadows: [
                Shadow(blurRadius: 10.0, color: Colors.black, offset: Offset(0, 1))
              ]
            ),
          ),
          const SizedBox(height: 150),
        ],
      ),
    );
  }

  // --- Indicator and Button Widgets (No changes needed) ---

  Widget _buildPageIndicator() {
    List<Widget> indicators = [];
    // Use the rounded page value for the indicator, or 0 if not initialized
    final int roundedPage = _pageController.hasClients && _pageController.page != null 
        ? _pageController.page!.round() 
        : 0;

    for (int i = 0; i < _numPages; i++) {
      indicators.add(_indicator(i == roundedPage));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: indicators,
    );
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white54,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  Widget _buildActionButton(double currentPage) {
    final bool isLastPage = currentPage.round() == _numPages - 1;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: isLastPage ? Colors.purple : Colors.white, // Use a solid Pinterest red
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25), // More rounded corners
        ),
      ),
      onPressed: () {
        if (isLastPage) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginPage(), // Uses the imported class name
      ),
    );
  } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      },
      child: Text(
        isLastPage ? 'Get Started' : 'Next',
        style: TextStyle(
          fontSize: 18,
          color: isLastPage ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}