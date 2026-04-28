import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _navigateToLogin();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    AppColors.background,
                    AppColors.surfacePrimary,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            // Header Label
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'CHAMBRE D\'AGRICULTURE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildPulseRing(0.0),
                      _buildPulseRing(0.35),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                    children: const [
                      TextSpan(text: 'Agri'),
                      TextSpan(text: 'Sense', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cultivez la performance avec l\'IA',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.neutreMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Footer Dots
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPulseDot(0),
                    const SizedBox(width: 6),
                    _buildPulseDot(1),
                    const SizedBox(width: 6),
                    _buildPulseDot(2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseRing(double offset) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = (_pulseController.value + offset) % 1.0;
        final scale = 0.6 + (t * 1.0);
        final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.7;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        width: 92,
        height: 92,
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildPulseDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final shift = index * 0.2;
        final t = (_pulseController.value + shift) % 1.0;
        final curve = Curves.easeInOut.transform(t);
        final opacity = 0.3 + (0.4 * curve);
        final scale = 0.9 + (0.2 * curve);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
