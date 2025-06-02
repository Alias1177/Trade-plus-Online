#!/bin/bash

# SSL Certificate Auto-Renewal Setup for Trader Plus
# Usage: ./setup-ssl-renewal.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Setting up SSL certificate auto-renewal${NC}"

# Configuration
DATA_PATH="/opt/tradeplus/certbot"
COMPOSE_FILE="/opt/tradeplus/docker-compose.prod.yml"
ENV_FILE="/opt/tradeplus/prod.env"

# Create renewal script
echo -e "${YELLOW}📝 Creating renewal script...${NC}"
cat > /opt/tradeplus/renew-ssl.sh << 'EOF'
#!/bin/bash

# SSL Certificate Renewal Script
# This script is run by cron twice daily

LOGFILE="/opt/tradeplus/ssl-renewal.log"
DATA_PATH="/opt/tradeplus/certbot"
COMPOSE_FILE="/opt/tradeplus/docker-compose.prod.yml"
ENV_FILE="/opt/tradeplus/prod.env"

echo "$(date): Starting SSL certificate renewal check" >> $LOGFILE

# Attempt certificate renewal
docker run --rm \
  -v "$DATA_PATH/conf:/etc/letsencrypt" \
  -v "$DATA_PATH/www:/var/www/certbot" \
  --network="tradeplus_backend-network" \
  certbot/certbot:latest \
  renew --webroot --webroot-path=/var/www/certbot --quiet

# Check if renewal was successful
if [ $? -eq 0 ]; then
    echo "$(date): Certificate renewal check completed successfully" >> $LOGFILE
    
    # Test nginx configuration
    if docker compose -f "$COMPOSE_FILE" exec frontend nginx -t > /dev/null 2>&1; then
        # Reload nginx to use renewed certificates
        docker compose -f "$COMPOSE_FILE" exec frontend nginx -s reload
        echo "$(date): Nginx reloaded with renewed certificates" >> $LOGFILE
    else
        echo "$(date): ERROR - Nginx configuration test failed" >> $LOGFILE
    fi
else
    echo "$(date): ERROR - Certificate renewal failed" >> $LOGFILE
fi

# Clean up old log entries (keep last 100 lines)
tail -n 100 $LOGFILE > $LOGFILE.tmp && mv $LOGFILE.tmp $LOGFILE

echo "$(date): Renewal process completed" >> $LOGFILE
EOF

# Make renewal script executable
chmod +x /opt/tradeplus/renew-ssl.sh

echo -e "${GREEN}✅ Renewal script created at /opt/tradeplus/renew-ssl.sh${NC}"

# Set up cron job
echo -e "${YELLOW}⏰ Setting up cron job for automatic renewal...${NC}"

# Check if cron is running
if ! systemctl is-active --quiet cron; then
    echo -e "${YELLOW}📋 Starting cron service...${NC}"
    systemctl start cron
    systemctl enable cron
fi

# Add cron job (runs twice daily at 2:30 AM and 2:30 PM)
CRON_JOB="30 2,14 * * * /opt/tradeplus/renew-ssl.sh >/dev/null 2>&1"

# Remove existing cron job if any
crontab -l 2>/dev/null | grep -v "renew-ssl.sh" | crontab -

# Add new cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo -e "${GREEN}✅ Cron job added successfully${NC}"
echo -e "${YELLOW}📅 Certificates will be checked for renewal twice daily${NC}"

# Create test script
echo -e "${YELLOW}🧪 Creating test script...${NC}"
cat > /opt/tradeplus/test-ssl-renewal.sh << 'EOF'
#!/bin/bash

# Test SSL Certificate Renewal
echo "🧪 Testing SSL certificate renewal process..."

# Run the renewal script manually
/opt/tradeplus/renew-ssl.sh

# Check the log
echo ""
echo "📋 Last 10 renewal log entries:"
tail -n 10 /opt/tradeplus/ssl-renewal.log

# Test certificate expiry
echo ""
echo "🔍 Certificate expiry check:"
echo | openssl s_client -servername trader-plus.online -connect trader-plus.online:443 2>/dev/null | openssl x509 -noout -dates
EOF

chmod +x /opt/tradeplus/test-ssl-renewal.sh

echo -e "${GREEN}✅ Test script created at /opt/tradeplus/test-ssl-renewal.sh${NC}"

# Show current cron jobs
echo -e "${YELLOW}📋 Current cron jobs:${NC}"
crontab -l

echo -e "${GREEN}🎉 SSL auto-renewal setup completed!${NC}"
echo -e "${GREEN}📋 Summary:${NC}"
echo -e "• Certificates will be checked twice daily (2:30 AM and 2:30 PM)"
echo -e "• Renewal logs: /opt/tradeplus/ssl-renewal.log"
echo -e "• Test renewal: ./test-ssl-renewal.sh"
echo -e "• Manual renewal: ./renew-ssl.sh" 