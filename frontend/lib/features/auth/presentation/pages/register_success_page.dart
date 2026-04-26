import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/core/theme/app_theme.dart';

class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 100,
              ),
              const SizedBox(height: 32),
              Text(
                'Compte créé avec succès !',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Work In Progress (WIP)',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Prochaine étape : Configuration de votre exploitation.\nNous préparons cet outil pour vous.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.neutreMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Simulons une redirection vers le dashboard ou accueil
                  context.go('/login'); 
                },
                child: const Text('Configurer mon exploitation plus tard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
