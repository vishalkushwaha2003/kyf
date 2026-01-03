import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kyf/features/home/home_tab.dart';
import 'package:kyf/features/wiredrobe/wiredrobe_tab.dart';
import 'package:kyf/features/reel/reel_tab.dart';
import 'package:kyf/features/chat/chat_tab.dart';

/// Main Navigation Shell with Material 3 NavigationBar
/// Contains 4 tabs: Home, Wiredrobe, Reel, Chat

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Tab pages
  static const List<Widget> _pages = [
    HomeTab(),
    WiredrobeTab(),
    ReelTab(),
    ChatTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onDestinationSelected,
        selectedIndex: _currentIndex,
        indicatorColor: theme.colorScheme.primaryContainer,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: theme.shadowColor,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 400),
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home_rounded),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.checkroom_rounded),
            icon: Icon(Icons.checkroom_outlined),
            label: 'Wiredrobe',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.play_circle_rounded),
            icon: Icon(Icons.play_circle_outline_rounded),
            label: 'Reel',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
