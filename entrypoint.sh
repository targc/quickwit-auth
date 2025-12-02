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

# Function to handle cleanup
cleanup() {
    echo "Received shutdown signal, stopping processes..."
    if [ ! -z "$QUICKWIT_PID" ]; then
        kill $QUICKWIT_PID
        wait $QUICKWIT_PID 2>/dev/null || true
    fi
    if [ ! -z "$NGINX_PID" ]; then
        kill $NGINX_PID
        wait $NGINX_PID 2>/dev/null || true
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Start nginx in background
echo "Starting nginx..."
nginx -g 'daemon off;' &
NGINX_PID=$!

# Start Quickwit in background
echo "Starting Quickwit..."
quickwit run --config /quickwit/config/quickwit.yaml &
QUICKWIT_PID=$!

echo "Both services started. PIDs: Quickwit=$QUICKWIT_PID, Nginx=$NGINX_PID"

# Wait for either process to exit
wait
