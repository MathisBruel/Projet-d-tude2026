import re
from datetime import datetime
from bson import ObjectId
from ..data_access.post_repository import PostRepository
from ..data_access.user_repository import UserRepository
from ..data_access.parcel_repository import ParcelRepository
from ..entities.post import Post, Reply
from ..dto.community_dto import PostResponse, _format_user_name, _format_user_role


def _user_location(user_id):
    if not user_id:
        return 'France'
    parcel = ParcelRepository.find_first_with_region(user_id)
    if parcel and parcel.get('region'):
        return parcel.get('region')
    return 'France'


def _enrich_post(post_data, current_user_id=None, include_replies=False):
    author = UserRepository.find_by_id_raw(post_data.get('user_id'))

    liked_by = post_data.get('liked_by', [])
    liked_by_me = False
    if current_user_id:
        liked_by_me = str(current_user_id) in [str(uid) for uid in liked_by]

    replies_enriched = None
    if include_replies:
        replies_enriched = []
        for reply in post_data.get('replies', []):
            reply_user = UserRepository.find_by_id_raw(reply.get('user_id'))
            replies_enriched.append({
                "author_name": _format_user_name(reply_user),
                "author_role": _format_user_role(reply_user),
                "author_avatar_url": reply_user.get('avatar_url') if reply_user else None,
                "content": reply.get('content'),
                "created_at": reply.get('created_at').isoformat() if reply.get('created_at') else None,
            })

    return PostResponse.from_data(
        post_data, author,
        replies_enriched=replies_enriched,
        liked_by_me=liked_by_me,
        author_location=_user_location(post_data.get('user_id')),
    )


def list_posts(tag=None, search=None, page=1, limit=10, current_user_id=None):
    page = max(1, page)
    limit = min(50, max(1, limit))
    query = {}

    if tag and tag.lower() != 'tous':
        query["tags"] = tag

    if search:
        escaped = re.escape(search)
        search_query = {
            "$or": [
                {"title": {"$regex": escaped, "$options": "i"}},
                {"content": {"$regex": escaped, "$options": "i"}},
                {"tags": {"$regex": escaped, "$options": "i"}},
            ]
        }
        if query:
            query = {"$and": [query, search_query]}
        else:
            query = search_query

    posts, total = PostRepository.find_paginated(query, page, limit)
    response_posts = [_enrich_post(p, current_user_id) for p in posts]

    return {
        "posts": response_posts,
        "page": page,
        "limit": limit,
        "total": total,
        "has_more": (page - 1) * limit + limit < total,
    }


def get_post(post_id, current_user_id=None):
    post_data = PostRepository.find_by_id(post_id)
    if not post_data:
        return None
    return _enrich_post(post_data, current_user_id, include_replies=True)


def create_post(user_id, title, content, tags, image_url=None):
    new_post = Post(
        user_id=user_id,
        title=title,
        content=content,
        tags=tags,
        replies=[],
        likes_count=0,
        liked_by=[],
        image_url=image_url,
    )
    inserted_id = PostRepository.insert(new_post)
    post_data = PostRepository.find_by_id(inserted_id)
    return _enrich_post(post_data, user_id)


def add_reply(post_id, user_id, content):
    reply = Reply(user_id=user_id, content=content, created_at=datetime.utcnow())
    matched = PostRepository.add_reply(post_id, reply.to_mongo())
    if matched == 0:
        return None
    post_data = PostRepository.find_by_id(post_id)
    return _enrich_post(post_data, user_id, include_replies=True)


def like_post(post_id, user_id):
    post_data = PostRepository.find_by_id(post_id)
    if not post_data:
        return None

    liked_by = post_data.get('liked_by', [])
    user_id_str = str(user_id)
    is_liked = user_id_str in {str(uid) for uid in liked_by}

    PostRepository.toggle_like(post_id, user_id_str, is_liked)
    PostRepository.fix_negative_likes(post_id)

    post_data = PostRepository.find_by_id(post_id)
    return _enrich_post(post_data, user_id, include_replies=True)
