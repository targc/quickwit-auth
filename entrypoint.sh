#!/bin/bash
set -e

# Create htpasswd from environment variables
if [ -n "$QUICKWIT_USERNAME" ] && [ -n "$QUICKWIT_PASSWORD" ]; then
    echo "$QUICKWIT_USERNAME:$(openssl passwd -apr1 "$QUICKWIT_PASSWORD")" > /etc/nginx/.htpasswd
    echo "Auth configured for user: $QUICKWIT_USERNAME"
else
    echo "admin:$(openssl passwd -apr1 "admin")" > /etc/nginx/.htpasswd
    echo "Default auth: admin/admin"
fi

# Start Quickwit in background
echo "Starting Quickwit..."
quickwit run &

# Start nginx in foreground
echo "Starting nginx..."
exec nginx -g 'daemon off;'
