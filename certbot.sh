#!/bin/sh

# ==========================
# CONFIG
# ==========================
DOMAIN="yourdomain.com"
EMAIL="you@yourdomain.com"
WEBROOT="/var/www/certbot"
LIVE_DIR="/etc/letsencrypt/live/$DOMAIN"
MIN_VALID_DAYS=7

# ==========================
# FUNCTIONS
# ==========================

is_cert_valid() {
  # returns 0 if cert is valid for more than MIN_VALID_DAYS
  openssl x509 \
    -checkend $((MIN_VALID_DAYS * 86400)) \
    -noout \
    -in "$LIVE_DIR/fullchain.pem"
}

# ==========================
# MAIN LOOP
# ==========================
trap exit TERM

while :; do
  echo "🔍 Checking certificates for $DOMAIN"

  if [ -f "$LIVE_DIR/fullchain.pem" ]; then

    if is_cert_valid; then
      echo "✅ Certificate is healthy"
    else
      echo "⚠️ Certificate expiring soon — regenerating"
      rm -rf /etc/letsencrypt/*
    fi
  else
    echo "❌ No certificate found — issuing new one"
    rm -rf /etc/letsencrypt/*
  fi

  if [ ! -f "$LIVE_DIR/fullchain.pem" ]; then
    certbot certonly \
      --webroot \
      --webroot-path "$WEBROOT" \
      --cert-name "$DOMAIN" \
      --force-renewal \
      --non-interactive \
      --email "$EMAIL" \
      --agree-tos \
      --no-eff-email \
      -d "$DOMAIN" \
      --deploy-hook 'touch /etc/letsencrypt/.reload-nginx';
  fi

  echo "⏳ Sleeping for 12 hours"
  sleep 12h
done
