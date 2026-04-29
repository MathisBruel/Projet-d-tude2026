import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';

class AdminPostsPage extends StatefulWidget {
  const AdminPostsPage({Key? key}) : super(key: key);

  @override
  State<AdminPostsPage> createState() => _AdminPostsPageState();
}

class _AdminPostsPageState extends State<AdminPostsPage> {
  late Future<List<Map<String, dynamic>>> _postsFuture;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = _fetchPosts();
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    final resp = await ApiService.getAdminPosts(limit: 100);
    if (resp['data'] != null) {
      final posts = resp['data'] as List<dynamic>;
      return posts.map((p) => Map<String, dynamic>.from(p as Map)).toList();
    }
    return [];
  }

  void _showPostDetails(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(post['title'] ?? 'Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Auteur', post['author_email'] ?? '-'),
              _buildDetailRow('Créé le', post['created_at'] ?? '-'),
              _buildDetailRow('Réponses', (post['reply_count'] ?? 0).toString()),
              const SizedBox(height: 12),
              const Text('Contenu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post['content'] ?? '',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              _deletePost(post['_id']);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deletePost(String postId) {
    // TODO: Implement API call to delete post
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post supprimé')),
    );
    _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _postsFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> posts = snapshot.data ?? [];

        // Filter posts
        if (_searchQuery.isNotEmpty) {
          posts = posts.where((p) {
            final title = (p['title'] as String? ?? '').toLowerCase();
            final content = (p['content'] as String? ?? '').toLowerCase();
            final query = _searchQuery.toLowerCase();
            return title.contains(query) || content.contains(query);
          }).toList();
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
                        'Gestion des Posts',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutreDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${posts.length} posts trouvés',
                        style: const TextStyle(fontSize: 13, color: AppColors.neutreMedium),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _loadPosts(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Rafraîchir'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Search
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Rechercher par titre ou contenu...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Posts grid
              if (posts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Aucun post trouvé',
                      style: TextStyle(color: AppColors.neutreMedium),
                    ),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: posts.take(50).map((post) => _buildPostCard(post)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final title = post['title'] as String? ?? 'Sans titre';
    final content = post['content'] as String? ?? '';
    final author = post['author_email'] as String? ?? 'Anonyme';
    final replyCount = post['reply_count'] as int? ?? 0;
    final createdAt = post['created_at'] as String? ?? '';

    String dateStr = '';
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) {
        dateStr = 'Aujourd\'hui';
      } else if (diff.inDays == 1) {
        dateStr = 'Hier';
      } else {
        dateStr = '${diff.inDays}j';
      }
    } catch (_) {
      dateStr = 'N/A';
    }

    return GestureDetector(
      onTap: () => _showPostDetails(post),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.split('@').first,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.neutreDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.neutreMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.neutreDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutreMedium,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.neutreMedium),
                const SizedBox(width: 4),
                Text(
                  '$replyCount réponse${replyCount > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.neutreMedium),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'delete') {
                      _deletePost(post['_id']);
                    }
                  },
                  itemBuilder: (BuildContext ctx) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('Voir'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                  child: const Icon(Icons.more_vert_rounded, size: 16, color: AppColors.neutreMedium),
                ),
              ],
            ),
          ],
        ),
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
