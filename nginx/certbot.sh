#!/bin/sh
set -e

DOMAIN="yourdomain.com"
EMAIL="you@yourdomain.com"
WEBROOT="/var/www/certbot"
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
CERT="$CERT_DIR/fullchain.pem"


sync_latest_cert() {
  echo "[certbot] syncing latest cert + renewal config"

  BASE="/etc/letsencrypt"
  LIVE_BASE="$BASE/live"
  RENEW_BASE="$BASE/renewal"

  TARGET_LIVE="$LIVE_BASE/$DOMAIN"
  TARGET_RENEW="$RENEW_BASE/$DOMAIN.conf"

  # Find latest live cert directory
  LATEST_LIVE=$(ls -d "$LIVE_BASE/$DOMAIN"* 2>/dev/null | sort -V | tail -n 1)

  if [ -z "$LATEST_LIVE" ]; then
    echo "[certbot] no live certs found"
    return 1
  fi

  # If latest is already the canonical directory, skip
  if [ "$LATEST_LIVE" = "$TARGET_LIVE" ]; then
    echo "[certbot] canonical live cert already latest — no sync needed"
  else
    echo "[certbot] latest live cert: $LATEST_LIVE → syncing"

    mkdir -p "$TARGET_LIVE"

    for f in cert.pem chain.pem fullchain.pem privkey.pem; do
      [ -f "$LATEST_LIVE/$f" ] && cp -f "$LATEST_LIVE/$f" "$TARGET_LIVE/$f"
    done

    chmod 600 "$TARGET_LIVE/privkey.pem" 2>/dev/null || true
    chmod 644 "$TARGET_LIVE/"*.pem 2>/dev/null || true
  fi

  # Find latest renewal config
  LATEST_RENEW=$(ls "$RENEW_BASE/$DOMAIN"*.conf 2>/dev/null | sort -V | tail -n 1)

  if [ -z "$LATEST_RENEW" ]; then
    echo "[certbot] no renewal config found"
    return 0
  fi

  # If latest renewal is already canonical, skip
  if [ "$LATEST_RENEW" = "$TARGET_RENEW" ]; then
    echo "[certbot] canonical renewal config already latest — no sync needed"
  else
    echo "[certbot] latest renewal config: $LATEST_RENEW → syncing"
    cp -f "$LATEST_RENEW" "$TARGET_RENEW"
  fi

  echo "[certbot] sync complete"
}


is_dummy() {
  [ ! -f "$CERT" ] && return 0
  openssl x509 -in "$CERT" -noout -subject | grep -q "CN=localhost"
}

issue_cert() {
  certbot certonly \
    --webroot \
    --webroot-path="$WEBROOT" \
    --cert-name "$DOMAIN" \
    --force-renewal \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --no-eff-email \
    -d "$DOMAIN"
}

renew_cert() {
  certbot renew \
    --cert-name "$DOMAIN" \
    --webroot \
    --webroot-path="$WEBROOT" \
    --non-interactive
}

sync_latest_cert

if is_dummy; then
  echo "[certbot] dummy or missing cert → issuing real cert"
  issue_cert
  sync_latest_cert
else
  echo "[certbot] real cert found → attempting renew"
  renew_cert
  sync_latest_cert
fi

while true; do
  sleep 12h
  echo "[certbot] periodic renewal check"
  renew_cert
  sync_latest_cert
done
