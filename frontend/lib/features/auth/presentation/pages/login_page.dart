import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';
import 'package:agrisense/core/services/auth_storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  AnimationController? _sunController;

  AnimationController get sunController {
    _sunController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    return _sunController!;
  }

  @override
  void dispose() {
    _sunController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result.containsKey('token')) {
      // Sauvegarder le token et l'ID utilisateur
      await AuthStorageService.saveToken(result['token'] as String);
      await AuthStorageService.saveUserId(result['user']['_id'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Bonjour ${result['user']['first_name'] ?? ''} !'),
          ),
        );
        context.go('/home');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(result['error'] ?? 'Identifiants invalides'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentHeight = (constraints.maxHeight - 240).clamp(0.0, double.infinity);
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header Image/Graphic
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.surfacePrimary, AppColors.white],
                      ),
                    ),
                    child: Stack(
                      children: [
                        LoginHeaderBackground(animation: sunController),
                        Padding(
                          padding: const EdgeInsets.only(top: 16, left: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'AgriSense',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppColors.neutreDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Login Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          const Text(
                            'Bon retour 👋',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              color: AppColors.neutreDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Connectez-vous à votre exploitation',
                            style: TextStyle(fontSize: 14, color: AppColors.neutreMedium),
                          ),
                          const SizedBox(height: 24),
                          _AgriTextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            hintText: 'pierre.moreau@beauce.fr',
                            prefixIcon: Icons.mail_outline,
                          ),
                          const SizedBox(height: 12),
                          _AgriTextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            hintText: '••••••••••',
                            prefixIcon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.neutreMedium,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                              child: const Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Se connecter'),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: GestureDetector(
                              onTap: () => context.push('/register'),
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 14, color: AppColors.neutreMedium),
                                  children: [
                                    TextSpan(text: 'Pas encore de compte ? '),
                                    TextSpan(
                                      text: 'S\'inscrire',
                                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _LoginFooter(),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoginHeaderBackground extends StatelessWidget {
  const LoginHeaderBackground({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: LoginHeaderPainter(animation),
      ),
    );
  }
}

class LoginHeaderPainter extends CustomPainter {
  LoginHeaderPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final pulse = 0.6 + (0.4 * (0.5 + 0.5 * (Math.sin(t * 6.2831853))));
    final sun = Paint()..color = AppColors.secondary.withOpacity(0.7);
    final sunHalo = Paint()..color = AppColors.secondary.withOpacity(0.15 + 0.1 * pulse);
    final center = Offset(size.width * 0.82, size.height * 0.3);
    canvas.drawCircle(center, 30 + (2.5 * pulse), sun);
    canvas.drawCircle(center, 44 + (6 * pulse), sunHalo);

    final fieldLight = Paint()..color = AppColors.primaryLight.withOpacity(0.3);
    final fieldMid = Paint()..color = AppColors.primary.withOpacity(0.55);
    final fieldDark = Paint()..color = AppColors.primary;

    final p1 = Path()
      ..moveTo(0, size.height * 0.79)
      ..quadraticBezierTo(size.width * 0.26, size.height * 0.66, size.width * 0.52, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.76, size.height * 0.84, size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p1, fieldLight);

    final p2 = Path()
      ..moveTo(0, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.32, size.height * 0.72, size.width * 0.58, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.86, size.width, size.height * 0.81)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p2, fieldMid);

    final p3 = Path()
      ..moveTo(0, size.height * 0.94)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.87, size.width * 0.58, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.94, size.width, size.height * 0.9)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p3, fieldDark);

    final stalkPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final grainPaint = Paint()..color = AppColors.secondary.withOpacity(0.85);
    final stalkXs = [0.1, 0.28, 0.46, 0.66, 0.85];
    for (var i = 0; i < stalkXs.length; i++) {
      final x = size.width * stalkXs[i];
      final y = size.height * (0.88 - (i.isEven ? 0.0 : 0.03));
      canvas.drawLine(Offset(x, y), Offset(x, y - 18), stalkPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 3, y - 14), width: 4, height: 8), grainPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 3, y - 10), width: 4, height: 8), grainPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 3, y - 6), width: 4, height: 8), grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StackedAvatars extends StatelessWidget {
  const StackedAvatars({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 24,
      child: Stack(
        children: [
          _avatar(0, 'JP', AppColors.primary),
          _avatar(14, 'MR', AppColors.secondary),
          _avatar(28, 'LS', AppColors.primaryLight),
        ],
      ),
    );
  }

  Widget _avatar(double left, String initials, Color color) {
    return Positioned(
      left: left,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const StackedAvatars(),
        const SizedBox(width: 10),
        Text(
          'Utilisé par 2 400+ agriculteurs en France',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.neutreMedium,
          ),
        ),
      ],
    );
  }
}

class _AgriTextField extends StatelessWidget {
  const _AgriTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: AppColors.neutreMedium, size: 18),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
