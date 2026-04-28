import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/features/shared/widgets/bottom_nav_bar.dart';

class PredictPage extends StatelessWidget {
  const PredictPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prédictions IA'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutreDark,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Module IA',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('À venir...'),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(activeTab: 'predict'),
    );
  }
}
