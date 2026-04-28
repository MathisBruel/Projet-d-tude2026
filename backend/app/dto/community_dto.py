class CreatePostRequest:
    def __init__(self, title, content, tags=None, image_url=None):
        self.title = title
        self.content = content
        self.tags = tags or []
        self.image_url = image_url

    def validate(self):
        if not self.title or not self.content:
            return "Titre et contenu requis"
        if not isinstance(self.tags, list):
            return "Les tags doivent etre une liste"
        return None


class ReplyRequest:
    def __init__(self, data: dict):
        self.content = data.get('content')

    def validate(self):
        if not self.content:
            return "Contenu requis"
        return None


class PostResponse:
    @staticmethod
    def from_data(post_data, author, replies_enriched=None, liked_by_me=False, author_location='France'):
        response = {
            "id": str(post_data.get('_id')),
            "title": post_data.get('title'),
            "content": post_data.get('content'),
            "tags": post_data.get('tags', []),
            "likes_count": post_data.get('likes_count', 0),
            "liked_by_me": liked_by_me,
            "image_url": post_data.get('image_url'),
            "replies_count": len(post_data.get('replies', [])),
            "created_at": post_data.get('created_at').isoformat() if post_data.get('created_at') else None,
            "author_name": _format_user_name(author),
            "author_role": _format_user_role(author),
            "author_location": author_location,
            "author_avatar_url": author.get('avatar_url') if author else None,
        }
        if replies_enriched is not None:
            response["replies"] = replies_enriched
        return response


def _format_user_name(user):
    if not user:
        return 'Utilisateur'
    first = user.get('first_name') or ''
    last = user.get('last_name') or ''
    full = f"{first} {last}".strip()
    return full if full else (user.get('email') or 'Utilisateur')


def _format_user_role(user):
    if not user:
        return 'farmer'
    return user.get('role') or 'farmer'
