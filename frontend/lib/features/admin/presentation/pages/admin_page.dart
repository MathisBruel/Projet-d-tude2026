import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:agrisense/features/admin/presentation/pages/admin_users_page.dart';
import 'package:agrisense/features/admin/presentation/pages/admin_posts_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  final List<({String label, IconData icon, Widget page})> _sections = [
    (
      label: 'Tableau de Bord',
      icon: Icons.dashboard_rounded,
      page: const AdminDashboardPage(),
    ),
    (
      label: 'Utilisateurs',
      icon: Icons.people_rounded,
      page: const AdminUsersPage(),
    ),
    (
      label: 'Posts',
      icon: Icons.forum_rounded,
      page: const AdminPostsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel Admin'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutreDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showLogoutDialog(),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfacePrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Administration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutreDark,
                        ),
                      ),
                      const Text(
                        'AgriSense',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutreMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (ctx, i) => _buildNavItem(i),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              Text(
                                'Administrateur',
                                style: TextStyle(fontSize: 11, color: AppColors.neutreMedium),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _sections[_selectedIndex].page,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    final section = _sections[index];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfacePrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                section.icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.neutreMedium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.neutreMedium,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement logout
            },
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}
