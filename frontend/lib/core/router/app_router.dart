import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/features/auth/presentation/pages/splash_page.dart';
import 'package:agrisense/features/auth/presentation/pages/login_page.dart';
import 'package:agrisense/features/auth/presentation/pages/register_page.dart';
import 'package:agrisense/features/auth/presentation/pages/register_success_page.dart';
import 'package:agrisense/features/home/presentation/pages/home_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/register-success',
        builder: (context, state) => const RegisterSuccessPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
