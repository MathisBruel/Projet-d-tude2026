from flask import Blueprint, jsonify, request
from ..services.auth_service import jwt_required
from ..data_access.user_repository import UserRepository
from ..data_access.post_repository import PostRepository
from ..data_access.prediction_repository import PredictionRepository
from ..data_access.parcel_repository import ParcelRepository
from datetime import datetime, timedelta

admin_bp = Blueprint('admin', __name__)


def _require_admin(f):
    """Décorateur pour vérifier que l'utilisateur est admin"""
    from functools import wraps
    @wraps(f)
    @jwt_required
    def decorated_function(*args, **kwargs):
        user_repo = UserRepository()
        user = user_repo.find_by_id(getattr(request, 'user_id', None))
        if not user or user.get('role') != 'admin':
            return jsonify({'error': 'Accès refusé : admin requis'}), 403
        return f(*args, **kwargs)
    return decorated_function


@admin_bp.route('/api/v1/admin/stats', methods=['GET'])
@_require_admin
def get_stats():
    """Récupère les statistiques globales de la plateforme"""
    try:
        user_repo = UserRepository()
        post_repo = PostRepository()
        pred_repo = PredictionRepository()
        parcel_repo = ParcelRepository()

        # Stats totales
        total_users = user_repo.count()
        total_posts = post_repo.count()
        total_predictions = pred_repo.count()
        total_parcels = parcel_repo.count()

        # Users ce mois
        now = datetime.now()
        month_start = datetime(now.year, now.month, 1)
        users_this_month = user_repo.count({'created_at': {'$gte': month_start}})

        # Prédictions cette semaine
        week_ago = now - timedelta(days=7)
        predictions_this_week = pred_repo.count({'created_at': {'$gte': week_ago}})

        # Confiance moyenne
        predictions = pred_repo.find_many({}, limit=1000)
        confidences = [p.get('confidence_pct', 0) for p in predictions]
        avg_confidence = sum(confidences) / len(confidences) if confidences else 0

        return jsonify({
            'status': 'success',
            'data': {
                'total_users': total_users,
                'total_posts': total_posts,
                'total_predictions': total_predictions,
                'total_parcels': total_parcels,
                'users_this_month': users_this_month,
                'predictions_this_week': predictions_this_week,
                'avg_prediction_confidence': round(avg_confidence, 1),
            }
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/api/v1/admin/users', methods=['GET'])
@_require_admin
def get_users():
    """Liste tous les utilisateurs"""
    try:
        limit = request.args.get('limit', default=100, type=int)
        offset = request.args.get('offset', default=0, type=int)

        user_repo = UserRepository()
        users = user_repo.find_many({}, skip=offset, limit=limit)

        # Nettoyer les données sensibles
        for u in users:
            u.pop('password_hash', None)

        return jsonify({
            'status': 'success',
            'data': users,
            'total': user_repo.count()
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/api/v1/admin/users/<user_id>/status', methods=['POST'])
@_require_admin
def toggle_user_status(user_id):
    """Active/désactive un utilisateur"""
    try:
        data = request.get_json()
        is_active = data.get('is_active', True)

        user_repo = UserRepository()
        result = user_repo.update(user_id, {'is_active': is_active})

        if result.modified_count > 0:
            return jsonify({
                'status': 'success',
                'message': f'Utilisateur {"activé" if is_active else "désactivé"}'
            }), 200
        else:
            return jsonify({'error': 'Utilisateur non trouvé'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/api/v1/admin/posts', methods=['GET'])
@_require_admin
def get_posts():
    """Liste tous les posts"""
    try:
        limit = request.args.get('limit', default=100, type=int)
        offset = request.args.get('offset', default=0, type=int)

        post_repo = PostRepository()
        posts = post_repo.find_many({}, skip=offset, limit=limit)

        return jsonify({
            'status': 'success',
            'data': posts,
            'total': post_repo.count()
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/api/v1/admin/posts/<post_id>', methods=['DELETE'])
@_require_admin
def delete_post(post_id):
    """Supprime un post"""
    try:
        post_repo = PostRepository()
        result = post_repo.delete(post_id)

        if result.deleted_count > 0:
            return jsonify({
                'status': 'success',
                'message': 'Post supprimé'
            }), 200
        else:
            return jsonify({'error': 'Post non trouvé'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500
