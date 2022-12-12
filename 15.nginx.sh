#!/bin/bash
domain="${1:-}"
mkdir -p /etc/pki/nginx/private /tmp/letsencrypt/.well-known
if [ ! -f /etc/pki/nginx/private/server.key ];then
    openssl req -x509 -newkey rsa:4096 -keyout /etc/pki/nginx/private/server.key -out /etc/pki/nginx/server.crt -sha256 -days 365 -nodes
    chown root. /etc/pki/nginx/private/server.key /etc/pki/nginx/server.crt
    chmod 600 /etc/pki/nginx/private/server.key
    chmod 644 /etc/pki/nginx/server.crt
fi
if [ ! -z "$domain" ]; then
    echo "Preparing temporary certificate for domain: $domain"
    cat /etc/pki/nginx/private/server.key > /etc/pki/nginx/private/$domain.key
    cat /etc/pki/nginx/server.crt > /etc/pki/nginx/$domain.crt
    chmod 600 /etc/pki/nginx/private/$domain.key
    chmod 644 /etc/pki/nginx/$domain.crt
fi
