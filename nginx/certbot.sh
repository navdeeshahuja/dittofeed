#!/bin/sh
set -e

DOMAIN="yourdomain.com"
EMAIL="you@yourdomain.com"
WEBROOT="/var/www/certbot"
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
CERT="$CERT_DIR/fullchain.pem"

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

if is_dummy; then
  echo "[certbot] dummy or missing cert → issuing real cert"
  issue_cert
else
  echo "[certbot] real cert found → attempting renew"
  renew_cert
fi

while true; do
  sleep 12h
  echo "[certbot] periodic renewal check"
  renew_cert
done
