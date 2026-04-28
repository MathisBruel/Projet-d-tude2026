import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisense/core/theme/app_theme.dart';
import 'package:agrisense/core/services/api_service.dart';
import 'package:agrisense/core/config/app_config.dart';
import 'package:agrisense/features/community/presentation/models/community_post.dart';

class CommunityDetailPage extends StatefulWidget {
  final String postId;
  final Object? post;

  const CommunityDetailPage({
    super.key,
    required this.postId,
    this.post,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  late Future<CommunityPost> _postFuture;
  final TextEditingController _replyController = TextEditingController();
  bool _isSendingReply = false;

  @override
  void initState() {
    super.initState();
    _postFuture = _loadPost();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<CommunityPost> _loadPost() async {
    final response = await ApiService.getCommunityPost(widget.postId);
    if (response['error'] != null) {
      throw Exception(response['error']);
    }
    final postJson = response['post'] as Map<String, dynamic>?;
    if (postJson == null) {
      throw Exception('Post introuvable');
    }
    return CommunityPost.fromJson(postJson);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _refreshPost() async {
    setState(() {
      _postFuture = _loadPost();
    });
  }

  Future<void> _likePost() async {
    final response = await ApiService.likeCommunityPost(widget.postId);
    if (response['error'] != null) {
      _showSnack(response['error'].toString());
      return;
    }
    _refreshPost();
  }

  Future<void> _sendReply() async {
    if (_isSendingReply) {
      return;
    }
    final content = _replyController.text.trim();
    if (content.isEmpty) {
      _showSnack('Votre reponse est vide');
      return;
    }

    setState(() {
      _isSendingReply = true;
    });
    final response = await ApiService.addCommunityReply(widget.postId, {
      'content': content,
    });
    setState(() {
      _isSendingReply = false;
    });

    if (response['error'] != null) {
      _showSnack(response['error'].toString());
      return;
    }

    _replyController.clear();
    _refreshPost();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<CommunityPost>(
          future: _postFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 48, color: AppColors.neutreMedium),
                    const SizedBox(height: 10),
                    Text(
                      'Discussion introuvable',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              );
            }

            final resolvedPost = snapshot.data!;
            return Column(
              children: [
                _TopBar(
                  onBack: () => context.pop(),
                  onShare: () => _showSnack('Partager la discussion'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    children: [
                      _DiscussionHeader(post: resolvedPost, onTap: () => _showSnack('Auteur')),
                      const SizedBox(height: 14),
                      _PostBody(
                        post: resolvedPost,
                        onSaveTap: () => _showSnack('Sauvegarde'),
                        onTagTap: (tag) => _showSnack('Tag: $tag'),
                        onLikeTap: _likePost,
                      ),
                      const SizedBox(height: 16),
                      _RepliesHeader(
                        count: resolvedPost.replies.length,
                        onSortTap: () => _showSnack('Tri des reponses'),
                      ),
                      const SizedBox(height: 10),
                      ...resolvedPost.replies
                          .map((reply) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ReplyCard(
                                  reply: reply,
                                  onTap: () => _showSnack('Profil reponse'),
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
                _ReplyComposer(
                  controller: _replyController,
                  isSending: _isSendingReply,
                  onSend: _sendReply,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onShare});

  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          _IconPillButton(icon: Icons.arrow_back, onTap: onBack),
          const SizedBox(width: 10),
          Text(
            'Discussion',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const Spacer(),
          _IconPillButton(icon: Icons.share_outlined, onTap: onShare),
        ],
      ),
    );
  }
}

class _DiscussionHeader extends StatelessWidget {
  const _DiscussionHeader({required this.post, required this.onTap});

  final CommunityPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
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
          Row(
            children: [
              _MetaCounter(icon: Icons.favorite, value: post.likesCount.toString()),
              const SizedBox(width: 8),
              _MetaCounter(icon: Icons.mode_comment_outlined, value: post.repliesCount.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({
    required this.post,
    required this.onSaveTap,
    required this.onTagTap,
    required this.onLikeTap,
  });

  final CommunityPost post;
  final VoidCallback onSaveTap;
  final ValueChanged<String> onTagTap;
  final VoidCallback onLikeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0A102814), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 12),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.neutreDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.body,
            style: const TextStyle(
              fontSize: 13,
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
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: onLikeTap,
                child: Row(
                  children: [
                    Icon(
                      (post.likedByMe ?? false) ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.likesCount.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutreMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onSaveTap,
                child: Text(
                  'Sauvegarder',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepliesHeader extends StatelessWidget {
  const _RepliesHeader({required this.count, required this.onSortTap});

  final int count;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$count reponses',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.neutreDark,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onSortTap,
          child: Text(
            'Plus recentes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({required this.reply, required this.onTap});

  final CommunityReply reply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x0F1C2B2D)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(
              initials: _initialsFromName(reply.authorName),
              size: 36,
              avatarUrl: reply.avatarUrl,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        reply.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutreDark,
                        ),
                      ),
                      if (reply.isExpert)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAmber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'EXPERT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reply.role} · ${reply.timeAgo}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutreMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reply.message,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.neutreDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.onSend,
    required this.isSending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(initials: 'PM', size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neutreLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Votre reponse...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutreDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: isSending ? null : onSend,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSending ? AppColors.neutreLight : AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.send_rounded,
                color: isSending ? AppColors.neutreMedium : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
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

class _MetaCounter extends StatelessWidget {
  const _MetaCounter({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.neutreMedium,
          ),
        ),
      ],
    );
  }
}

class _IconPillButton extends StatelessWidget {
  const _IconPillButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x0F1C2B2D)),
        ),
        child: Icon(icon, color: AppColors.neutreDark, size: 18),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.size = 40, this.avatarUrl});

  final String initials;
  final double size;
  final String? avatarUrl;

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

String _resolveImageUrl(String path) {
  if (path.startsWith('http')) {
    return path;
  }
  return '${AppConfig.apiUrl}$path';
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
