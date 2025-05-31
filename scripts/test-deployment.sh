#!/bin/bash

echo "🚀 Testing Trade Plus Deployment..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BASE_URL=${1:-"http://localhost"}
TIMEOUT=10

# Helper functions
check_service() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -n "Testing $name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$url")
    
    if [ "$response" = "$expected_status" ]; then
        echo -e "${GREEN}✓ OK${NC} (HTTP $response)"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $response)"
        return 1
    fi
}

test_api_endpoint() {
    local endpoint=$1
    local method=${2:-GET}
    local data=$3
    
    echo -n "Testing API $endpoint... "
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT \
            -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$BASE_URL$endpoint")
    fi
    
    if [ "$response" -ge 200 ] && [ "$response" -lt 400 ]; then
        echo -e "${GREEN}✓ OK${NC} (HTTP $response)"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $response)"
        return 1
    fi
}

# Main tests
echo "🔍 Running health checks..."
echo

# Test frontend
check_service "Frontend" "$BASE_URL/"

# Test backend health
check_service "Backend Health" "$BASE_URL/health"

# Test pages
check_service "Pay Page" "$BASE_URL/pay"

echo
echo "🧪 Testing API endpoints..."
echo

# Test OPTIONS (CORS preflight)
echo -n "Testing CORS preflight... "
response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT \
    -X OPTIONS \
    -H "Origin: $BASE_URL" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" \
    "$BASE_URL/insert")

if [ "$response" = "204" ] || [ "$response" = "200" ]; then
    echo -e "${GREEN}✓ OK${NC} (HTTP $response)"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $response)"
fi

# Test API with valid data
valid_data='{"selected_id":"Id1","number":"1234567890","email":"test@example.com","TGNikName":"testuser"}'
test_api_endpoint "/insert" "POST" "$valid_data"

# Test API with duplicate email (should fail)
echo -n "Testing duplicate email validation... "
response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$valid_data" \
    "$BASE_URL/insert")

if [ "$response" = "409" ]; then
    echo -e "${GREEN}✓ OK${NC} (HTTP $response - Conflict as expected)"
else
    echo -e "${YELLOW}? UNEXPECTED${NC} (HTTP $response - Expected 409)"
fi

# Test API with invalid data
invalid_data='{"selected_id":"","number":"","email":"","TGNikName":""}'
echo -n "Testing invalid data validation... "
response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$invalid_data" \
    "$BASE_URL/insert")

if [ "$response" = "400" ]; then
    echo -e "${GREEN}✓ OK${NC} (HTTP $response - Bad Request as expected)"
else
    echo -e "${YELLOW}? UNEXPECTED${NC} (HTTP $response - Expected 400)"
fi

echo
echo "📊 Testing performance..."
echo

# Simple load test
echo -n "Testing response time... "
start_time=$(date +%s%N)
curl -s -o /dev/null "$BASE_URL/" --max-time $TIMEOUT
end_time=$(date +%s%N)
duration=$((($end_time - $start_time) / 1000000))

if [ $duration -lt 1000 ]; then
    echo -e "${GREEN}✓ FAST${NC} (${duration}ms)"
elif [ $duration -lt 3000 ]; then
    echo -e "${YELLOW}○ OK${NC} (${duration}ms)"
else
    echo -e "${RED}✗ SLOW${NC} (${duration}ms)"
fi

echo
echo "🏁 Deployment test completed!"
echo
echo "💡 Tips:"
echo "  • Monitor logs: docker compose -f docker-compose.prod.yml logs -f"
echo "  • Check health: curl $BASE_URL/health"
echo "  • View metrics: docker stats" 