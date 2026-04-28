from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
import os
import re
from bson import ObjectId
from datetime import datetime
from ..database import get_db
from ..models.post import Post, Reply
from ..utils.auth_utils import jwt_required

community_bp = Blueprint('community', __name__, url_prefix='/api/v1/community')


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


def _user_location(db, user_id):
    if not user_id:
        return 'France'
    parcel = db.parcels.find_one({"user_id": ObjectId(user_id), "region": {"$ne": None}})
    if parcel and parcel.get('region'):
        return parcel.get('region')
    return 'France'


def _post_to_response(db, post_data, include_replies=False):
    author = db.users.find_one({"_id": post_data.get('user_id')})
    replies = post_data.get('replies', [])
    liked_by = post_data.get('liked_by', [])
    liked_by_me = False
    if hasattr(request, 'user_id') and request.user_id:
        liked_by_me = str(request.user_id) in [str(uid) for uid in liked_by]

    response = {
        "id": str(post_data.get('_id')),
        "title": post_data.get('title'),
        "content": post_data.get('content'),
        "tags": post_data.get('tags', []),
        "likes_count": post_data.get('likes_count', 0),
        "liked_by_me": liked_by_me,
        "image_url": post_data.get('image_url'),
        "replies_count": len(replies),
        "created_at": post_data.get('created_at').isoformat() if post_data.get('created_at') else None,
        "author_name": _format_user_name(author),
        "author_role": _format_user_role(author),
        "author_location": _user_location(db, post_data.get('user_id')),
        "author_avatar_url": author.get('avatar_url') if author else None,
    }

    if include_replies:
        enriched_replies = []
        for reply in replies:
            reply_user = db.users.find_one({"_id": reply.get('user_id')})
            enriched_replies.append({
                "author_name": _format_user_name(reply_user),
                "author_role": _format_user_role(reply_user),
                "author_avatar_url": reply_user.get('avatar_url') if reply_user else None,
                "content": reply.get('content'),
                "created_at": reply.get('created_at').isoformat() if reply.get('created_at') else None,
            })
        response["replies"] = enriched_replies

    return response


@community_bp.route('/posts', methods=['GET'])
@jwt_required
def list_posts():
    db = get_db()
    tag = request.args.get('tag')
    search = request.args.get('search')
    page = request.args.get('page', 1, type=int)
    limit = request.args.get('limit', 10, type=int)

    # Validate pagination params
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

    skip = (page - 1) * limit
    total = db.posts.count_documents(query)
    posts = list(db.posts.find(query).sort("created_at", -1).skip(skip).limit(limit))
    response_posts = [_post_to_response(db, post) for post in posts]

    return jsonify({
        "posts": response_posts,
        "page": page,
        "limit": limit,
        "total": total,
        "has_more": skip + limit < total
    }), 200


@community_bp.route('/posts/<post_id>', methods=['GET'])
@jwt_required
def get_post(post_id):
    db = get_db()
    try:
        post_data = db.posts.find_one({"_id": ObjectId(post_id)})
    except Exception:
        return jsonify({"error": "Post invalide"}), 400

    if not post_data:
        return jsonify({"error": "Post non trouve"}), 404

    return jsonify({"post": _post_to_response(db, post_data, include_replies=True)}), 200


@community_bp.route('/posts', methods=['POST'])
@jwt_required
def create_post():
    if request.is_json:
        data = request.get_json()
        title = data.get('title') if data else None
        content = data.get('content') if data else None
        tags = data.get('tags', []) if data else []
    else:
        title = request.form.get('title')
        content = request.form.get('content')
        tags = request.form.get('tags', '')
        if tags:
            tags = [tag.strip() for tag in tags.split(',') if tag.strip()]
        else:
            tags = []

    if not title or not content:
        return jsonify({"error": "Titre et contenu requis"}), 400

    if not isinstance(tags, list):
        return jsonify({"error": "Les tags doivent etre une liste"}), 400

    image_url = None
    if 'image' in request.files:
        file = request.files['image']
        if file and file.filename:
            filename = secure_filename(file.filename)
            ext = os.path.splitext(filename)[1].lower()
            if ext not in ['.jpg', '.jpeg', '.png', '.webp']:
                return jsonify({"error": "Format d'image non supporte"}), 400
            unique_name = f"{request.user_id}_{int(datetime.utcnow().timestamp())}{ext}"
            upload_path = os.path.join(current_app.config['UPLOAD_FOLDER'], unique_name)
            file.save(upload_path)
            image_url = f"/uploads/{unique_name}"

    new_post = Post(
        user_id=request.user_id,
        title=title,
        content=content,
        tags=tags,
        replies=[],
        likes_count=0,
        liked_by=[],
        image_url=image_url,
    )

    db = get_db()
    result = db.posts.insert_one(new_post.to_mongo())
    post_data = db.posts.find_one({"_id": result.inserted_id})

    return jsonify({"post": _post_to_response(db, post_data)}), 201


@community_bp.route('/posts/<post_id>/replies', methods=['POST'])
@jwt_required
def add_reply(post_id):
    data = request.get_json()
    if not data or not data.get('content'):
        return jsonify({"error": "Contenu requis"}), 400

    db = get_db()
    try:
        post_object_id = ObjectId(post_id)
    except Exception:
        return jsonify({"error": "Post invalide"}), 400

    reply = Reply(
        user_id=request.user_id,
        content=data.get('content'),
        created_at=datetime.utcnow(),
    )

    update_result = db.posts.update_one(
        {"_id": post_object_id},
        {"$push": {"replies": reply.to_mongo() if hasattr(reply, 'to_mongo') else reply.to_dict()}, "$set": {"updated_at": datetime.utcnow()}},
    )

    if update_result.matched_count == 0:
        return jsonify({"error": "Post non trouve"}), 404

    post_data = db.posts.find_one({"_id": post_object_id})
    return jsonify({"post": _post_to_response(db, post_data, include_replies=True)}), 200


@community_bp.route('/posts/<post_id>/like', methods=['POST'])
@jwt_required
def like_post(post_id):
    db = get_db()
    try:
        post_object_id = ObjectId(post_id)
    except Exception:
        return jsonify({"error": "Post invalide"}), 400

    post_data = db.posts.find_one({"_id": post_object_id})
    if not post_data:
        return jsonify({"error": "Post non trouve"}), 404

    liked_by = post_data.get('liked_by', [])
    user_id = str(request.user_id)
    liked_set = {str(uid) for uid in liked_by}

    if user_id in liked_set:
        db.posts.update_one(
            {"_id": post_object_id},
            {
                "$pull": {"liked_by": user_id},
                "$inc": {"likes_count": -1},
                "$set": {"updated_at": datetime.utcnow()},
            },
        )
    else:
        db.posts.update_one(
            {"_id": post_object_id},
            {
                "$addToSet": {"liked_by": user_id},
                "$inc": {"likes_count": 1},
                "$set": {"updated_at": datetime.utcnow()},
            },
        )

    post_data = db.posts.find_one({"_id": post_object_id})
    if post_data and post_data.get('likes_count', 0) < 0:
        db.posts.update_one(
            {"_id": post_object_id},
            {"$set": {"likes_count": 0}},
        )
        post_data['likes_count'] = 0

    return jsonify({"post": _post_to_response(db, post_data, include_replies=True)}), 200
