#!/bin/bash
#
# 🔐 Setup Nginx + SSL (Let's Encrypt)
# Run this after the VPS is created and DNS is pointing to it
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if domain is provided
if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <domain>${NC}"
    echo "Example: $0 agent.mysite.com"
    exit 1
fi

DOMAIN=$1
EMAIL="${2:-admin@$DOMAIN}"

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║     🔐 Nginx + SSL Setup                 ║"
echo "║                                          ║"
echo "║  Domain: $DOMAIN"
echo "║  Email: $EMAIL"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Verify DNS is pointing to this server
echo -e "${YELLOW}🔍 Verifying DNS...${NC}"
SERVER_IP=$(curl -s ifconfig.me)
DNS_IP=$(dig +short $DOMAIN | tail -1)

if [ "$SERVER_IP" != "$DNS_IP" ]; then
    echo -e "${RED}❌ DNS not pointing to this server!${NC}"
    echo "   Server IP: $SERVER_IP"
    echo "   DNS points to: $DNS_IP"
    echo ""
    echo "Please update your DNS A record to point to $SERVER_IP"
    echo "Then wait a few minutes and run this script again."
    exit 1
fi
echo -e "${GREEN}✅ DNS verified: $DOMAIN → $SERVER_IP${NC}"

# Install nginx and certbot
echo -e "${YELLOW}📦 Installing Nginx and Certbot...${NC}"
apt-get update -qq
apt-get install -y -qq nginx certbot python3-certbot-nginx

# Create webroot for Let's Encrypt
mkdir -p /var/www/certbot
mkdir -p /var/www/clawdbot

# Create simple status page
cat > /var/www/clawdbot/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Clawdbot Agent</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #0a0a0b;
            color: #fafafa;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        h1 { 
            font-size: 3rem;
            margin-bottom: 0.5rem;
        }
        .status {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.3);
            padding: 0.5rem 1rem;
            border-radius: 9999px;
            color: #10b981;
            margin-top: 1rem;
        }
        .dot {
            width: 8px;
            height: 8px;
            background: #10b981;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        .footer {
            margin-top: 2rem;
            color: #71717a;
            font-size: 0.875rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🤖</h1>
        <h2>Clawdbot Agent</h2>
        <div class="status">
            <span class="dot"></span>
            Online
        </div>
        <p class="footer">OpenClaw AI Agent</p>
    </div>
</body>
</html>
HTML

# Create initial nginx config (HTTP only for certbot)
cat > /etc/nginx/sites-available/clawdbot << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        root /var/www/clawdbot;
        index index.html;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/clawdbot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload nginx
nginx -t
systemctl reload nginx

# Get SSL certificate
echo -e "${YELLOW}🔐 Obtaining SSL certificate...${NC}"
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect

# Create final nginx config with SSL
cat > /etc/nginx/sites-available/clawdbot << EOF
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name $DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS Server
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # SSL Certificates
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Webhook endpoint
    location /webhook {
        proxy_pass http://127.0.0.1:18789;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }

    # Status page
    location / {
        root /var/www/clawdbot;
        index index.html;
        try_files \$uri \$uri/ =404;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Reload nginx with final config
nginx -t && systemctl reload nginx

# Setup auto-renewal
echo -e "${YELLOW}⏰ Setting up auto-renewal...${NC}"
systemctl enable certbot.timer
systemctl start certbot.timer

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ SSL Setup Complete!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "Your agent is now available at:"
echo -e "  ${BLUE}https://$DOMAIN${NC}"
echo ""
echo -e "Webhook URL for external services:"
echo -e "  ${BLUE}https://$DOMAIN/webhook${NC}"
echo ""
echo -e "SSL certificate will auto-renew via certbot.timer"
echo ""
