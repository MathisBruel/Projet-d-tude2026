class UpdateProfileRequest:
    ALLOWED_FIELDS = ['first_name', 'last_name', 'phone', 'location_name', 'location_lat', 'location_lng']

    def __init__(self, data: dict):
        self.updates = {k: data[k] for k in self.ALLOWED_FIELDS if k in data}

    def validate(self):
        if not self.updates:
            return "Aucun champ valide fourni"
        return None


class ProfileResponse:
    @staticmethod
    def from_user(user):
        return {
            "id": str(user.get('_id')),
            "email": user.get('email'),
            "role": user.get('role'),
            "first_name": user.get('first_name'),
            "last_name": user.get('last_name'),
            "phone": user.get('phone'),
            "location_name": user.get('location_name'),
            "location_lat": user.get('location_lat'),
            "location_lng": user.get('location_lng'),
            "avatar_url": user.get('avatar_url'),
        }
