#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
LOCAL_SETTINGS="$SCRIPT_DIR/instance/LocalSettings.php"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================="
echo "  MediaWiki Startup Script"
echo "========================================="
echo ""

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please run ./setup.sh first to configure your wiki."
    exit 1
fi

# Source the .env file
# shellcheck source=/dev/null
source "$ENV_FILE"

# Create instance directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/instance"

# Check if LocalSettings.php exists
if [ ! -f "$LOCAL_SETTINGS" ]; then
    echo -e "${YELLOW}LocalSettings.php not found - starting in SETUP MODE${NC}"
    echo ""
    echo "This is your first time starting this wiki."
    echo "The installation wizard will be available in your browser."
    echo ""

    # Check which mode (dev or prod)
    if [ "$1" = "prod" ]; then
        echo -e "${RED}Error: Cannot start in production mode without LocalSettings.php${NC}"
        echo ""
        echo "Production requires a configured LocalSettings.php file."
        echo "Please complete setup in development mode first:"
        echo ""
        echo "  1. Run: ${YELLOW}./start.sh${NC} (without 'prod' argument)"
        echo "  2. Complete the MediaWiki installation wizard"
        echo "  3. Download and configure LocalSettings.php"
        echo "  4. Then run: ${YELLOW}./start.sh prod${NC}"
        echo ""
        exit 1
    else
        echo -e "${BLUE}Starting in DEVELOPMENT mode (setup)...${NC}"
        docker compose -f docker-compose.yml -f docker-compose.init.yml up -d
        echo ""
        echo -e "${GREEN}✓ Containers started${NC}"
        echo ""
        echo "Next steps:"
        echo -e "1. Open your browser to: ${YELLOW}http://localhost:${DEV_PORT}${NC}"
        echo "2. Complete the MediaWiki installation wizard"
        echo -e "   Database host: ${YELLOW}${CONTAINER_DB_NAME}${NC}"
        echo -e "   Database name: ${YELLOW}${DB_NAME}${NC}"
        echo -e "   Database user: ${YELLOW}${DB_USER}${NC}"
        echo -e "   Database password: ${YELLOW}${DB_PASSWORD}${NC}"
        echo "3. Download the generated LocalSettings.php"
        echo -e "4. Save it to: ${YELLOW}${LOCAL_SETTINGS}${NC}"
        echo -e "5. Configure the server URL: ${YELLOW}./configure-localsettings.sh${NC}"
        echo -e "6. Run: ${YELLOW}./start.sh${NC} again to restart in normal mode"
    fi

    echo ""
    echo -e "${YELLOW}Tip: Quick copy and configure:${NC}"
    echo -e "  cp ~/Downloads/LocalSettings.php ${LOCAL_SETTINGS}"
    if [ "$1" = "prod" ]; then
        echo -e "  ./configure-localsettings.sh prod"
    else
        echo -e "  ./configure-localsettings.sh"
    fi
    echo ""

else
    echo -e "${GREEN}LocalSettings.php found - starting in NORMAL MODE${NC}"
    echo ""

    # Check which mode (dev or prod)
    if [ "$1" = "prod" ]; then
        echo -e "${BLUE}Starting in PRODUCTION mode...${NC}"
        docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
        echo ""
        echo -e "${GREEN}✓ Wiki is running${NC}"
        echo ""
        echo -e "Access your wiki at: ${YELLOW}https://${PROD_DOMAIN}${NC}"
    else
        echo -e "${BLUE}Starting in DEVELOPMENT mode...${NC}"
        docker compose up -d
        echo ""
        echo -e "${GREEN}✓ Wiki is running${NC}"
        echo ""
        echo -e "Access your wiki at: ${YELLOW}http://localhost:${DEV_PORT}${NC}"
    fi

    echo ""
    echo "Useful commands:"
    echo -e "  ${YELLOW}docker compose logs -f${NC}          - View logs"
    echo -e "  ${YELLOW}docker compose down${NC}             - Stop containers"
    echo -e "  ${YELLOW}./backup-mediawiki.sh${NC}           - Create backup"
fi

echo ""
