#!/usr/bin/env bash
set -e

echo "🔧 Docker-Tools Setup"

read -p "Webserver-Name [web]: " WEB_NAME
read -p "Webserver-Port [8080]: " WEB_PORT
read -p "Adminer-Port [8081]: " ADMINER_PORT
read -p "DB-User [user]: " DB_USER
read -p "DB-Pass [pass]: " DB_PASS
read -p "DB-Name [app]: " DB_NAME

cat > .env <<ENV
WEB_NAME=${WEB_NAME:-web}
WEB_PORT=${WEB_PORT:-8080}
ADMINER_PORT=${ADMINER_PORT:-8081}
DB_USER=${DB_USER:-user}
DB_PASS=${DB_PASS:-pass}
DB_NAME=${DB_NAME:-app}
ENV
echo "✅ .env geschrieben."

# HTML erstellen, falls fehlt
mkdir -p html
if [ ! -f html/index.html ]; then
  echo "<h1>Hallo von ${WEB_NAME:-web} 🚀</h1>" > html/index.html
  echo "✅ html/index.html erstellt."
fi

read -p "Container jetzt starten? [Y/n] " GO
if [[ "${GO}" =~ ^([nN]|no)$ ]]; then
  echo "Okay. Starte später mit: docker compose up -d"
else
  docker compose up -d
  echo "✅ Läuft!"
  echo "  Web:     http://localhost:${WEB_PORT:-8080}"
  echo "  Adminer: http://localhost:${ADMINER_PORT:-8081} (Server: db)"
fi
