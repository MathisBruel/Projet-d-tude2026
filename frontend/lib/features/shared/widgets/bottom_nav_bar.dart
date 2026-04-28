import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/core/theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final String activeTab;

  const BottomNavBar({
    Key? key,
    required this.activeTab,
  }) : super(key: key);

  void _navigate(BuildContext context, int index) {
    final routes = ['/home', '/map', '/predict', '/community'];
    GoRouter.of(context).go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getTabIndex(activeTab),
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.neutreMedium,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Carte',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_rounded),
          label: 'IA',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_rounded),
          label: 'Communauté',
        ),
      ],
      onTap: (index) => _navigate(context, index),
    );
  }

  int _getTabIndex(String tab) {
    switch (tab) {
      case 'home':
        return 0;
      case 'map':
        return 1;
      case 'predict':
        return 2;
      case 'community':
        return 3;
      default:
        return 0;
    }
  }
}
