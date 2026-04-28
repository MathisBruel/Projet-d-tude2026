import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/features/shared/widgets/bottom_nav_bar.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Communauté'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutreDark,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Module Communauté',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('À venir...'),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'community'),
    );
  }
}
