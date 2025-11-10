#!/bin/bash

# Quick setup script for OpenAI proxy on VPS
# Run on server: bash <(curl -s https://raw.githubusercontent.com/.../setup.sh)

echo "🚀 Setting up OpenAI Proxy..."

# Update system
echo "📦 Updating system..."
apt update && apt upgrade -y

# Install Nginx
echo "📦 Installing Nginx..."
apt install nginx -y

# Create Nginx config
echo "⚙️  Creating Nginx config..."
cat > /etc/nginx/sites-available/openai-proxy <<'EOF'
server {
    listen 80;
    server_name 5.181.1.229;

    access_log /var/log/nginx/openai-proxy.access.log;
    error_log /var/log/nginx/openai-proxy.error.log;

    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;

    location / {
        proxy_pass https://api.openai.com;
        proxy_set_header Host api.openai.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1.2 TLSv1.3;
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF

# Enable config
echo "🔗 Enabling config..."
ln -sf /etc/nginx/sites-available/openai-proxy /etc/nginx/sites-enabled/

# Remove default
rm -f /etc/nginx/sites-enabled/default

# Test config
echo "✅ Testing Nginx config..."
nginx -t

# Restart Nginx
echo "🔄 Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

# Setup firewall (if ufw is active)
if command -v ufw &> /dev/null; then
    echo "🔥 Configuring firewall..."
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Test from your Mac:"
echo "curl http://5.181.1.229/v1/models -H 'Authorization: Bearer YOUR_KEY'"
echo ""
echo "View logs:"
echo "tail -f /var/log/nginx/openai-proxy.access.log"
