from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
import os
from datetime import datetime
from ..dto.community_dto import CreatePostRequest, ReplyRequest
from ..services import community_service
from ..services.auth_service import jwt_required

community_bp = Blueprint('community', __name__, url_prefix='/api/v1/community')


@community_bp.route('/posts', methods=['GET'])
@jwt_required
def list_posts():
    tag = request.args.get('tag')
    search = request.args.get('search')
    page = request.args.get('page', 1, type=int)
    limit = request.args.get('limit', 10, type=int)

    result = community_service.list_posts(
        tag=tag, search=search, page=page, limit=limit,
        current_user_id=request.user_id,
    )
    return jsonify(result), 200


@community_bp.route('/posts/<post_id>', methods=['GET'])
@jwt_required
def get_post(post_id):
    try:
        result = community_service.get_post(post_id, current_user_id=request.user_id)
    except Exception:
        return jsonify({"error": "Post invalide"}), 400

    if not result:
        return jsonify({"error": "Post non trouve"}), 404
    return jsonify({"post": result}), 200


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

    # Handle image upload
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

    dto = CreatePostRequest(title, content, tags, image_url)
    error = dto.validate()
    if error:
        return jsonify({"error": error}), 400

    result = community_service.create_post(request.user_id, title, content, tags, image_url)
    return jsonify({"post": result}), 201


@community_bp.route('/posts/<post_id>/replies', methods=['POST'])
@jwt_required
def add_reply(post_id):
    data = request.get_json()
    if not data:
        return jsonify({"error": "Payload JSON manquant"}), 400

    dto = ReplyRequest(data)
    error = dto.validate()
    if error:
        return jsonify({"error": error}), 400

    try:
        result = community_service.add_reply(post_id, request.user_id, dto.content)
    except Exception:
        return jsonify({"error": "Post invalide"}), 400

    if not result:
        return jsonify({"error": "Post non trouve"}), 404
    return jsonify({"post": result}), 200


@community_bp.route('/posts/<post_id>/like', methods=['POST'])
@jwt_required
def like_post(post_id):
    try:
        result = community_service.like_post(post_id, request.user_id)
    except Exception:
        return jsonify({"error": "Post invalide"}), 400

    if not result:
        return jsonify({"error": "Post non trouve"}), 404
    return jsonify({"post": result}), 200
