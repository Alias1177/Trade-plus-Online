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

# Stop any existing frontend
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
docker compose -f docker-compose.prod.yml stop frontend || true

# Use temporary nginx config for certificate generation
echo -e "${YELLOW}🔧 Switching to temporary HTTP-only nginx config...${NC}"
cp TradePlusOnline/nginx.conf TradePlusOnline/nginx.conf.backup
cp TradePlusOnline/nginx-temp.conf TradePlusOnline/nginx.conf

# Rebuild frontend with temporary config
echo -e "${YELLOW}🔨 Rebuilding frontend container...${NC}"
docker compose -f docker-compose.prod.yml build --no-cache frontend

# Start nginx with temporary config
echo -e "${YELLOW}🚀 Starting nginx with temporary HTTP config...${NC}"
docker compose -f docker-compose.prod.yml --env-file prod.env up -d frontend

# Wait for nginx to start
echo -e "${YELLOW}⏳ Waiting for nginx to start...${NC}"
sleep 15

# Check nginx status
if ! docker compose -f docker-compose.prod.yml exec frontend nginx -t; then
    echo -e "${RED}❌ Nginx configuration error${NC}"
    exit 1
fi

# Test that challenge directory is accessible
echo -e "${YELLOW}🧪 Testing challenge directory access...${NC}"
echo "test" | docker compose -f docker-compose.prod.yml exec -T frontend tee /var/www/certbot/test.txt > /dev/null
if curl -f -s "http://$DOMAIN/.well-known/acme-challenge/test.txt" | grep -q "test"; then
    echo -e "${GREEN}✅ Challenge directory is accessible${NC}"
else
    echo -e "${RED}❌ Challenge directory is not accessible${NC}"
    echo -e "${YELLOW}🔍 Debugging nginx configuration...${NC}"
    docker compose -f docker-compose.prod.yml exec frontend nginx -T
    exit 1
fi

# Clean up test file
docker compose -f docker-compose.prod.yml exec frontend rm -f /var/www/certbot/test.txt

# Request certificate
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
    
    # Restore original nginx config with HTTPS
    echo -e "${YELLOW}🔄 Restoring HTTPS nginx configuration...${NC}"
    cp TradePlusOnline/nginx.conf.backup TradePlusOnline/nginx.conf
    
    # Rebuild frontend with HTTPS config
    echo -e "${YELLOW}🔨 Rebuilding frontend with HTTPS config...${NC}"
    docker compose -f docker-compose.prod.yml build --no-cache frontend
    
    # Restart nginx with HTTPS
    echo -e "${YELLOW}🔄 Starting nginx with HTTPS configuration...${NC}"
    docker compose -f docker-compose.prod.yml --env-file prod.env up -d frontend
    
    # Wait for restart
    sleep 10
    
    # Test HTTPS
    echo -e "${YELLOW}🧪 Testing HTTPS connection...${NC}"
    if curl -f -s -I "https://$DOMAIN" > /dev/null; then
        echo -e "${GREEN}✅ HTTPS is working!${NC}"
    else
        echo -e "${YELLOW}⚠️ HTTPS test failed, but certificates are installed${NC}"
    fi
    
    echo -e "${GREEN}🎉 HTTPS setup completed!${NC}"
    echo -e "${GREEN}🌐 Your site should now be available at: https://$DOMAIN${NC}"
else
    echo -e "${RED}❌ Failed to obtain SSL certificate${NC}"
    echo -e "${YELLOW}💡 Try running with STAGING=1 for testing${NC}"
    
    # Restore original config even on failure
    cp TradePlusOnline/nginx.conf.backup TradePlusOnline/nginx.conf
    exit 1
fi

echo -e "${GREEN}📋 Next steps:${NC}"
echo -e "1. Test your site: https://$DOMAIN"
echo -e "2. Set up auto-renewal with: ./setup-ssl-renewal.sh"
echo -e "3. Check SSL rating: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN" 