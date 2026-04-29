import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({Key? key}) : super(key: key);

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late Future<List<Map<String, dynamic>>> _usersFuture;
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final resp = await ApiService.getAdminUsers(limit: 100);
    if (resp['data'] != null) {
      final users = resp['data'] as List<dynamic>;
      return users.map((u) => Map<String, dynamic>.from(u as Map)).toList();
    }
    return [];
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Détails - ${user['email']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user['email'] ?? '-'),
              _buildDetailRow('Rôle', user['role'] ?? '-'),
              _buildDetailRow('Créé le', user['created_at'] ?? '-'),
              _buildDetailRow('Dernière connexion', user['last_login'] ?? 'N/A'),
              _buildDetailRow('Statut', user['is_active'] == true ? 'Actif' : 'Inactif'),
              const SizedBox(height: 16),
              const Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          if (user['is_active'] == true)
            ElevatedButton(
              onPressed: () {
                _toggleUserStatus(user['_id'], false);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Désactiver'),
            )
          else
            ElevatedButton(
              onPressed: () {
                _toggleUserStatus(user['_id'], true);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Activer'),
            ),
        ],
      ),
    );
  }

  void _toggleUserStatus(String userId, bool activate) {
    // TODO: Implement API call to toggle user status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Utilisateur ${activate ? 'activé' : 'désactivé'}')),
    );
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _usersFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> users = snapshot.data ?? [];

        // Filter users
        if (_searchQuery.isNotEmpty) {
          users = users.where((u) {
            final email = (u['email'] as String? ?? '').toLowerCase();
            return email.contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (_roleFilter != 'all') {
          users = users.where((u) => u['role'] == _roleFilter).toList();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestion des Utilisateurs',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutreDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${users.length} utilisateurs trouvés',
                        style: const TextStyle(fontSize: 13, color: AppColors.neutreMedium),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _loadUsers(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Rafraîchir'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Filters
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par email...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _roleFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tous les rôles')),
                      DropdownMenuItem(value: 'farmer', child: Text('Agriculteurs')),
                      DropdownMenuItem(value: 'agronomist', child: Text('Agronomes')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrateurs')),
                    ],
                    onChanged: (val) => setState(() => _roleFilter = val ?? 'all'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Users table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.divider)),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: _buildHeaderCell('Email')),
                          Expanded(child: _buildHeaderCell('Rôle')),
                          Expanded(child: _buildHeaderCell('Statut')),
                          Expanded(child: _buildHeaderCell('Créé')),
                          Expanded(child: _buildHeaderCell('Actions')),
                        ],
                      ),
                    ),
                    if (users.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Aucun utilisateur trouvé',
                            style: TextStyle(color: AppColors.neutreMedium),
                          ),
                        ),
                      )
                    else
                      ...users.take(50).map((user) => _buildUserRow(user)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.neutreMedium,
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final email = user['email'] as String? ?? '-';
    final role = user['role'] as String? ?? '-';
    final isActive = user['is_active'] as bool? ?? true;
    final createdAt = user['created_at'] as String? ?? '-';

    String roleLabel = 'Agriculteur';
    Color roleColor = const Color(0xFF2E7D32);
    if (role == 'agronomist') {
      roleLabel = 'Agronome';
      roleColor = const Color(0xFF0277BD);
    } else if (role == 'admin') {
      roleLabel = 'Admin';
      roleColor = const Color(0xFFE65100);
    }

    String dateStr = '';
    try {
      final date = DateTime.parse(createdAt);
      dateStr = '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      dateStr = createdAt;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Text(
              dateStr,
              style: const TextStyle(fontSize: 12, color: AppColors.neutreMedium),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_rounded, size: 18, color: AppColors.primary),
                  onPressed: () => _showUserDetails(user),
                  tooltip: 'Voir détails',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                  onPressed: () {},
                  tooltip: 'Éditer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutreMedium, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
