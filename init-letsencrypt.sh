#!/bin/bash

# Init Let's Encrypt SSL Script for Trader Plus
# Usage: ./init-letsencrypt.sh

# Configuration
DOMAIN="trader-plus.online"
EMAIL="four-x-teams@mail.ru"
DATA_PATH="/opt/tradeplus/certbot"
STAGING=0 # Set to 1 for testing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔒 Initializing Let's Encrypt SSL for $DOMAIN${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running${NC}"
    exit 1
fi

# Create directories
echo -e "${YELLOW}📁 Creating SSL directories...${NC}"
mkdir -p "$DATA_PATH"/{conf,www}

# Check if certificates already exist
if [ -d "$DATA_PATH/conf/live/$DOMAIN" ]; then
    echo -e "${YELLOW}⚠️ Existing certificates found for $DOMAIN${NC}"
    read -p "Replace existing certificates? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ Keeping existing certificates${NC}"
        exit 0
    fi
fi

# Download recommended TLS parameters
echo -e "${YELLOW}📋 Downloading recommended TLS parameters...${NC}"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$DATA_PATH/conf/options-ssl-nginx.conf"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$DATA_PATH/conf/ssl-dhparams.pem"

# Create dummy certificate
echo -e "${YELLOW}🔧 Creating dummy certificate for $DOMAIN...${NC}"
path="/etc/letsencrypt/live/$DOMAIN"
mkdir -p "$DATA_PATH/conf/live/$DOMAIN"

docker run --rm -v "$DATA_PATH/conf:/etc/letsencrypt" --entrypoint "" \
  certbot/certbot:latest sh -c "
    openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'
    cp '$path/fullchain.pem' '$path/chain.pem'
"

echo -e "${YELLOW}🚀 Starting nginx with dummy certificate...${NC}"

# Start nginx
cd /opt/tradeplus
docker compose -f docker-compose.prod.yml --env-file prod.env up -d frontend

# Wait for nginx to start
echo -e "${YELLOW}⏳ Waiting for nginx to start...${NC}"
sleep 10

# Check nginx status
if ! docker compose -f docker-compose.prod.yml exec frontend nginx -t; then
    echo -e "${RED}❌ Nginx configuration error${NC}"
    exit 1
fi

# Delete dummy certificate
echo -e "${YELLOW}🗑️ Deleting dummy certificate...${NC}"
rm -rf "$DATA_PATH/conf/live/$DOMAIN"

# Request real certificate
echo -e "${YELLOW}🔐 Requesting SSL certificate for $DOMAIN...${NC}"

# Set up staging or production
if [ $STAGING != "0" ]; then
    STAGING_ARG="--staging"
    echo -e "${YELLOW}⚠️ Using Let's Encrypt staging environment${NC}"
else
    STAGING_ARG=""
    echo -e "${GREEN}🌍 Using Let's Encrypt production environment${NC}"
fi

# Request certificate
docker run --rm \
  -v "$DATA_PATH/conf:/etc/letsencrypt" \
  -v "$DATA_PATH/www:/var/www/certbot" \
  --network="tradeplus_backend-network" \
  certbot/certbot:latest \
  certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  $STAGING_ARG \
  -d "$DOMAIN" \
  -d "www.$DOMAIN"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
    
    # Restart nginx to use the real certificate
    echo -e "${YELLOW}🔄 Restarting nginx with real certificate...${NC}"
    docker compose -f docker-compose.prod.yml restart frontend
    
    echo -e "${GREEN}🎉 HTTPS setup completed!${NC}"
    echo -e "${GREEN}🌐 Your site is now available at: https://$DOMAIN${NC}"
else
    echo -e "${RED}❌ Failed to obtain SSL certificate${NC}"
    echo -e "${YELLOW}💡 Try running with STAGING=1 for testing${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Next steps:${NC}"
echo -e "1. Update your DNS to point to this server"
echo -e "2. Test your site: https://$DOMAIN"
echo -e "3. Set up auto-renewal with: ./setup-ssl-renewal.sh" 