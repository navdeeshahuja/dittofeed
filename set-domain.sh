#!/usr/bin/env bash

set -e

DOMAIN="$1"
EMAIL="$2"

# ---- Validation ----
if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
  echo "❌ Error: domain and email are required"
  echo "Usage: ./set-domain.sh <domain> <email>"
  exit 1
fi

if [[ ${#DOMAIN} -le 2 || ${#EMAIL} -le 2 ]]; then
  echo "❌ Error: domain and email must be longer than 2 characters"
  exit 1
fi

# ---- Confirmation ----
echo "You are about to set:"
echo "  DOMAIN = $DOMAIN"
echo "  EMAIL  = $EMAIL"
echo
read -p "Proceed? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

# ---- Replace in certbot.sh ----
if [[ -f certbot.sh ]]; then
  sed -i.bak \
    -e "s/^DOMAIN=\".*\"/DOMAIN=\"$DOMAIN\"/" \
    -e "s/^EMAIL=\".*\"/EMAIL=\"$EMAIL\"/" \
    certbot.sh
  echo "✅ Updated certbot.sh (backup: certbot.sh.bak)"
else
  echo "⚠️ certbot.sh not found"
fi

# ---- Replace in nginx config ----
NGINX_CONF="nginx/nginx-https-port443.conf"

if [[ -f "$NGINX_CONF" ]]; then
  sed -i.bak \
    -e "s/default [^;]*;/default $DOMAIN;/" \
    "$NGINX_CONF"
  echo "✅ Updated $NGINX_CONF (backup: nginx-https-port443.conf.bak)"
else
  echo "⚠️ $NGINX_CONF not found"
fi

echo "🎉 Done."
