class CommunityReply {
  final String authorName;
  final String role;
  final String timeAgo;
  final String message;
  final bool isExpert;

  const CommunityReply({
    required this.authorName,
    required this.role,
    required this.timeAgo,
    required this.message,
    this.isExpert = false,
  });

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    final role = _formatRole(json['author_role'] as String?);
    final createdAt = _parseDate(json['created_at'] as String?);
    return CommunityReply(
      authorName: (json['author_name'] as String?) ?? 'Utilisateur',
      role: role,
      timeAgo: _formatTimeAgo(createdAt),
      message: (json['content'] as String?) ?? '',
      isExpert: _isExpertRole(role),
    );
  }
}

class CommunityPost {
  final String id;
  final String authorName;
  final String role;
  final String location;
  final String timeAgo;
  final String title;
  final String body;
  final List<String> tags;
  final int repliesCount;
  final int likesCount;
  final bool isHot;
  final List<CommunityReply> replies;
  final String? imageUrl;
  final bool? likedByMe;

  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.role,
    required this.location,
    required this.timeAgo,
    required this.title,
    required this.body,
    required this.tags,
    required this.repliesCount,
    required this.likesCount,
    required this.isHot,
    required this.replies,
    required this.imageUrl,
    this.likedByMe = false,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final role = _formatRole(json['author_role'] as String?);
    final createdAt = _parseDate(json['created_at'] as String?);
    final repliesJson = (json['replies'] as List<dynamic>?) ?? [];
    final replies = repliesJson
        .whereType<Map<String, dynamic>>()
        .map(CommunityReply.fromJson)
        .toList();

    return CommunityPost(
      id: (json['id'] as String?) ?? '',
      authorName: (json['author_name'] as String?) ?? 'Utilisateur',
      role: role,
      location: (json['author_location'] as String?) ?? 'France',
      timeAgo: _formatTimeAgo(createdAt),
      title: (json['title'] as String?) ?? '',
      body: (json['content'] as String?) ?? '',
      tags: (json['tags'] as List<dynamic>?)?.whereType<String>().toList() ?? [],
      repliesCount: (json['replies_count'] as int?) ?? replies.length,
      likesCount: (json['likes_count'] as int?) ?? 0,
      isHot: (json['likes_count'] as int? ?? 0) >= 20,
      replies: replies,
      imageUrl: json['image_url'] as String?,
      likedByMe: json['liked_by_me'] == true,
    );
  }
}

String _formatRole(String? role) {
  switch (role) {
    case 'agronomist':
      return 'Agronome';
    case 'admin':
      return 'Admin';
    case 'farmer':
    default:
      return 'Agriculteur';
  }
}

bool _isExpertRole(String role) {
  return role == 'Agronome' || role == 'Admin';
}

DateTime? _parseDate(String? iso) {
  if (iso == null || iso.isEmpty) {
    return null;
  }
  return DateTime.tryParse(iso);
}

String _formatTimeAgo(DateTime? date) {
  if (date == null) {
    return 'a l\'instant';
  }
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) {
    return 'a l\'instant';
  }
  if (diff.inHours < 1) {
    return 'il y a ${diff.inMinutes} min';
  }
  if (diff.inDays < 1) {
    return 'il y a ${diff.inHours}h';
  }
  if (diff.inDays < 7) {
    return 'il y a ${diff.inDays}j';
  }
  return 'le ${date.day}/${date.month}';
}
