import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/config/app_config.dart';
import 'package:agrisense/features/shared/widgets/bottom_nav_bar.dart';
import 'package:agrisense/features/community/presentation/models/community_post.dart';
import 'package:agrisense/core/services/api_service.dart';
import 'package:go_router/go_router.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String _activeTag = 'Tous';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late ScrollController _scrollController;

  List<CommunityPost> _posts = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadMorePosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8 && !_isLoading && _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getCommunityPosts(
        tag: _activeTag == 'Tous' ? null : _activeTag,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage,
      );

      if (response['error'] != null) {
        setState(() => _error = response['error']);
        return;
      }

      final postsJson = (response['posts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final newPosts = postsJson.map(CommunityPost.fromJson).toList();

      setState(() {
        if (_isInitialLoad) {
          _posts = newPosts;
          _isInitialLoad = false;
        } else {
          _posts.addAll(newPosts);
        }
        _hasMore = response['has_more'] ?? false;
        _currentPage++;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Erreur de chargement');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _refreshPosts() {
    setState(() {
      _posts = [];
      _currentPage = 1;
      _hasMore = true;
      _isInitialLoad = true;
      _error = null;
    });
    _loadMorePosts();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _likePost(String postId) async {
    await ApiService.likeCommunityPost(postId);
    _refreshPosts();
  }

  Future<void> _openCreatePostPage() async {
    final created = await context.push<bool>('/community/create');
    if (created == true) {
      _refreshPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _CommunityHeader(
              onTap: () => _showSnack('Header selectionne'),
              onAddTap: _openCreatePostPage,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refreshPosts(),
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    _SearchBar(
                      controller: _searchController,
                      onChanged: (value) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                          _searchQuery = value.trim();
                          _refreshPosts();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _FilterChips(
                      activeTag: _activeTag,
                      onFilterTap: (tag) {
                        _activeTag = tag;
                        _refreshPosts();
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_isInitialLoad && _posts.isEmpty)
                      const _LoadingList()
                    else if (_error != null && _posts.isEmpty)
                      _EmptyState(
                        title: 'Impossible de charger la communaute',
                        subtitle: 'Verifiez votre connexion et reessayez.',
                        onRetry: _refreshPosts,
                      )
                    else if (_posts.isEmpty)
                      _EmptyState(
                        title: _searchQuery.isEmpty ? 'Aucun post pour le moment' : 'Aucun resultat',
                        subtitle: _searchQuery.isEmpty
                            ? 'Soyez le premier a lancer une discussion.'
                            : 'Essayez un autre mot-cle.',
                        onRetry: _refreshPosts,
                      )
                    else ...[
                      ..._posts.map((post) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PostCard(
                              post: post,
                              onTap: () => context.push(
                                '/community/post/${post.id}',
                                extra: post,
                              ),
                              onTagTap: (tag) => _showSnack('Tag: $tag'),
                              onReplyTap: () => context.push(
                                '/community/post/${post.id}',
                                extra: post,
                              ),
                              onLikeTap: () => _likePost(post.id),
                            ),
                          )),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      if (!_hasMore && _posts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Vous avez atteint la fin',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.neutreMedium,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const BottomNavBar(activeTab: 'community'),
          ],
        ),
      ),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({required this.onTap, required this.onAddTap});

  final VoidCallback onTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communaute',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  '124 agriculteurs en ligne · 8 nouveaux posts',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutreMedium,
                  ),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: onAddTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A2E7D32), blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0F1C2B2D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.neutreMedium),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Rechercher un sujet, un utilisateur...',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutreDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.activeTag, required this.onFilterTap});

  final String activeTag;
  final ValueChanged<String> onFilterTap;

  @override
  Widget build(BuildContext context) {
    const filters = ['Tous', 'Meteo', 'Maladie', 'Recolte', 'Sol', 'Irrigation', 'Fertilisation'];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final label = filters[index];
          final isActive = label == activeTag;
          return InkWell(
            onTap: () => onFilterTap(label),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.neutreDark : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x0F1C2B2D)),
              ),
              child: Row(
                children: [
                  if (label != 'Tous')
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterIcon(label: label),
                    ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.neutreMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}

class _FilterIcon extends StatelessWidget {
  const _FilterIcon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    switch (label.toLowerCase()) {
      case 'meteo':
        return const Icon(Icons.cloud_outlined, size: 14, color: AppColors.neutreMedium);
      case 'maladie':
        return const Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.neutreMedium);
      case 'recolte':
        return const Icon(Icons.agriculture_outlined, size: 14, color: AppColors.neutreMedium);
      case 'sol':
        return const Icon(Icons.terrain_outlined, size: 14, color: AppColors.neutreMedium);
      case 'irrigation':
        return const Icon(Icons.water_drop_outlined, size: 14, color: AppColors.neutreMedium);
      case 'fertilisation':
        return const Icon(Icons.science_outlined, size: 14, color: AppColors.neutreMedium);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onTagTap,
    required this.onReplyTap,
    required this.onLikeTap,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final ValueChanged<String> onTagTap;
  final VoidCallback onReplyTap;
  final VoidCallback onLikeTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x0F1C2B2D)),
          boxShadow: const [
            BoxShadow(color: Color(0x0A102814), blurRadius: 2, offset: Offset(0, 1)),
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(
                  initials: _initialsFromName(post.authorName),
                  avatarUrl: post.authorAvatarUrl,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutreDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.role} · ${post.location} · ${post.timeAgo}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutreMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.isHot)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hot',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.tags
                  .map((tag) => _TagChip(
                        label: tag,
                        tone: _tagTone(tag),
                        onTap: () => onTagTap(tag),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.neutreDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.neutreMedium,
              ),
            ),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _resolveImageUrl(post.imageUrl!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _MetaPill(
                  icon: Icons.mode_comment_outlined,
                  value: '${post.repliesCount} reponses',
                  onTap: onReplyTap,
                ),
                const SizedBox(width: 8),
                _MetaPill(
                  icon: (post.likedByMe ?? false) ? Icons.favorite : Icons.favorite_border,
                  value: post.likesCount.toString(),
                  onTap: onLikeTap,
                ),
                const Spacer(),
                InkWell(
                  onTap: onReplyTap,
                  child: Text(
                    'Repondre',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.value, required this.onTap});

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.neutreLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.neutreMedium),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.neutreMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.tone, required this.onTap});

  final String label;
  final _ChipTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: tone.foreground,
          ),
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neutreDark : AppColors.neutreLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check, size: 12, color: Colors.white),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.neutreMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x0F1C2B2D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _LoadingBar(width: 160),
              SizedBox(height: 8),
              _LoadingBar(width: 220),
              SizedBox(height: 12),
              _LoadingBar(width: 260),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.neutreLight,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 52, color: AppColors.neutreMedium),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutreMedium,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.avatarUrl, this.size = 40});

  final String initials;
  final String? avatarUrl;
  final double size;

  /// Check if the avatar URL is a valid image URL (not just initials)
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.surfacePrimary,
      backgroundImage: _isValidImageUrl(avatarUrl)
          ? NetworkImage('${AppConfig.apiUrl}$avatarUrl') as ImageProvider<Object>
          : null,
      child: (!_isValidImageUrl(avatarUrl))
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

class _ChipTone {
  final Color background;
  final Color foreground;

  const _ChipTone(this.background, this.foreground);
}

_ChipTone _tagTone(String label) {
  switch (label.toLowerCase()) {
    case 'maladie':
      return const _ChipTone(Color(0xFFFFEBEE), Color(0xFFD32F2F));
    case 'recolte':
      return const _ChipTone(Color(0xFFE3F2FD), Color(0xFF1565C0));
    case 'meteo':
      return const _ChipTone(Color(0xFFFFF8E1), Color(0xFFF57C00));
    case 'sol':
      return const _ChipTone(Color(0xFFE8F5E9), Color(0xFF2E7D32));
    case 'irrigation':
      return const _ChipTone(Color(0xFFE1F5FE), Color(0xFF0277BD));
    case 'fertilisation':
      return const _ChipTone(Color(0xFFF3E5F5), Color(0xFF6A1B9A));
    default:
      return const _ChipTone(AppColors.neutreLight, AppColors.neutreMedium);
  }
}

String _initialsFromName(String name) {
  final parts = name.trim().split(' ');
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + last).toUpperCase();
}

String _resolveImageUrl(String path) {
  if (path.startsWith('http')) {
    return path;
  }
  return '${AppConfig.apiUrl}$path';
}
