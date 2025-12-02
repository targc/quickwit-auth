FROM quickwit/quickwit:latest

# Install nginx in the same container
USER root
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose nginx port (will proxy to Quickwit on 7280)
EXPOSE 8080

# Set entrypoint to start both nginx and Quickwit (stay as root to manage nginx)
ENTRYPOINT ["/entrypoint.sh"]

