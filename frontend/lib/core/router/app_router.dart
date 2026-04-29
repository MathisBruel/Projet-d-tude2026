import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/features/auth/presentation/pages/splash_page.dart';
import 'package:agrisense/features/auth/presentation/pages/login_page.dart';
import 'package:agrisense/features/auth/presentation/pages/register_page.dart';
import 'package:agrisense/features/auth/presentation/pages/register_success_page.dart';
import 'package:agrisense/features/home/presentation/pages/home_page.dart';
import 'package:agrisense/features/map/presentation/pages/map_page.dart';
import 'package:agrisense/features/map/presentation/pages/add_parcel_page.dart';
import 'package:agrisense/features/predict/presentation/pages/predict_page.dart';
import 'package:agrisense/features/community/presentation/pages/community_page.dart';
import 'package:agrisense/features/community/presentation/pages/community_detail_page.dart';
import 'package:agrisense/features/community/presentation/pages/community_create_page.dart';
import 'package:agrisense/features/profile/presentation/pages/profile_page.dart';
import 'package:agrisense/features/admin/presentation/pages/admin_page.dart';

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
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: '/map/add',
        builder: (context, state) => const AddParcelPage(),
      ),
      GoRoute(
        path: '/predict',
        builder: (context, state) => const PredictPage(),
      ),
      GoRoute(
        path: '/community',
        builder: (context, state) => const CommunityPage(),
      ),
      GoRoute(
        path: '/community/create',
        builder: (context, state) => const CommunityCreatePage(),
      ),
      GoRoute(
        path: '/community/post/:id',
        builder: (context, state) {
          final postId = state.pathParameters['id'] ?? '';
          return CommunityDetailPage(postId: postId, post: state.extra);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPage(),
      ),
    ],
  );
}
