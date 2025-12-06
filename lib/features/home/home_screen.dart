// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _tabs = ['/home/explore', '/home/chat', '/home/profile'];

  @override
  void initState() {
    super.initState();
    // default route
    WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home/explore'));
  }

  void _onTap(int idx) {
    setState(() => _index = idx);
    context.go(_tabs[idx]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SafeArea(child: RouterPlaceholder()), // placeholder to show nested pages via go_router
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class RouterPlaceholder extends StatelessWidget {
  const RouterPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    // go_router renders nested child routes automatically in the route's builder,
    // so here we simply return a placeholder — actual screens are provided by the router.
    return const SizedBox.shrink();
  }
}
