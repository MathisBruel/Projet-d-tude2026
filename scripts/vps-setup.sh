#!/bin/bash
# Script de configuration du VPS pour AgriSense deployment

set -e

echo "🚀 Configuration du VPS pour AgriSense..."

# Vérifier si on est root ou avec sudo
if [ "$EUID" -ne 0 ]; then
   echo "❌ Ce script doit être exécuté avec sudo"
   exit 1
fi

# 1. Installer Docker si pas présent
if ! command -v docker &> /dev/null; then
    echo "📦 Installation de Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# 2. Installer Docker Compose si pas présent
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installation de Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# 3. Créer le répertoire de déploiement
DEPLOY_PATH="${VPS_DEPLOY_PATH:=/opt/agrisense}"
echo "📁 Création du répertoire de déploiement: $DEPLOY_PATH"
mkdir -p "$DEPLOY_PATH"
mkdir -p "$DEPLOY_PATH/backend"
mkdir -p "$DEPLOY_PATH/data"
chmod -R 755 "$DEPLOY_PATH"

# 4. Créer un .gitkeep pour tracker le répertoire (pas de repo git nécessaire)
touch "$DEPLOY_PATH/.gitkeep"

# 5. Configurer Docker pour se connecter à ghcr.io
echo "🔐 Configuration de Docker Container Registry..."
if [ ! -d "$HOME/.docker" ]; then
    mkdir -p "$HOME/.docker"
fi

# 6. Créer un fichier .env pour backend s'il n'existe pas
if [ ! -f "$DEPLOY_PATH/backend/.env" ]; then
    echo "⚙️  Création du fichier .env pour backend..."
    cat > "$DEPLOY_PATH/backend/.env" << 'EOF'
# MongoDB
MONGO_URI=mongodb://mongodb:27017/agrisense

# Gemini API
GEMINI_API_KEY=your_gemini_api_key_here

# Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# JWT
JWT_SECRET=your_secret_key_here

# Flask
FLASK_ENV=production
EOF
    echo "⚠️  Veuillez configurer les variables d'environnement dans: $DEPLOY_PATH/backend/.env"
fi

# 7. Créer le répertoire data pour MongoDB
mkdir -p "$DEPLOY_PATH/data"

# 8. Configurer les permissions
chown -R "$SUDO_USER:$SUDO_USER" "$DEPLOY_PATH" 2>/dev/null || true

echo ""
echo "✅ Configuration du VPS terminée!"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Configurer les secrets GitHub (voir docs/vps-deployment.md)"
echo "2. Éditer $DEPLOY_PATH/backend/.env avec vos variables d'environnement"
echo "3. Pousser du code vers 'main' pour déclencher le déploiement automatique"
echo ""
echo "📍 Répertoire de déploiement: $DEPLOY_PATH"
