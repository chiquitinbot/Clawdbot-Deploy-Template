#!/bin/bash
#
# 🔍 Validate Environment Configuration
# Checks that all required variables are set before deployment
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "🔍 Validating environment configuration..."
echo ""

# Load .env if exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
elif [ -f ../.env ]; then
    export $(grep -v '^#' ../.env | xargs)
fi

# Function to check required var
check_required() {
    local var_name=$1
    local var_value="${!var_name}"
    local description=$2
    
    if [ -z "$var_value" ]; then
        echo -e "${RED}❌ MISSING:${NC} $var_name"
        echo "   $description"
        ((ERRORS++))
    else
        # Mask the value for display
        local masked="${var_value:0:8}..."
        echo -e "${GREEN}✅${NC} $var_name = $masked"
    fi
}

# Function to check optional var
check_optional() {
    local var_name=$1
    local var_value="${!var_name}"
    local description=$2
    
    if [ -z "$var_value" ]; then
        echo -e "${YELLOW}⚠️  OPTIONAL:${NC} $var_name not set"
        echo "   $description"
        ((WARNINGS++))
    else
        local masked="${var_value:0:8}..."
        echo -e "${GREEN}✅${NC} $var_name = $masked"
    fi
}

echo "═══════════════════════════════════════════"
echo "  REQUIRED - Agent won't work without these"
echo "═══════════════════════════════════════════"
echo ""

check_required "ANTHROPIC_API_KEY" "Get from: https://console.anthropic.com/settings/keys"

echo ""
echo "═══════════════════════════════════════════"
echo "  COMMUNICATION - Need at least one"
echo "═══════════════════════════════════════════"
echo ""

HAS_CHANNEL=0

if [ -n "$DISCORD_BOT_TOKEN" ]; then
    echo -e "${GREEN}✅${NC} DISCORD_BOT_TOKEN = ${DISCORD_BOT_TOKEN:0:8}..."
    check_optional "DISCORD_GUILD_ID" "Server ID for your Discord server"
    check_optional "DISCORD_CHANNEL_ID" "Default channel for messages"
    HAS_CHANNEL=1
else
    echo -e "${YELLOW}⚠️${NC} Discord not configured"
fi

echo ""

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    echo -e "${GREEN}✅${NC} TELEGRAM_BOT_TOKEN = ${TELEGRAM_BOT_TOKEN:0:8}..."
    HAS_CHANNEL=1
else
    echo -e "${YELLOW}⚠️${NC} Telegram not configured"
fi

if [ $HAS_CHANNEL -eq 0 ]; then
    echo ""
    echo -e "${RED}❌ ERROR: No communication channel configured!${NC}"
    echo "   You need at least Discord OR Telegram"
    ((ERRORS++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  OPTIONAL - Recommended integrations"
echo "═══════════════════════════════════════════"
echo ""

check_optional "GEMINI_API_KEY" "For cheaper AI tasks - https://aistudio.google.com/apikey"
check_optional "GOG_ACCOUNT" "For Gmail/Calendar integration"
check_optional "AUTH_TOKEN" "For Twitter integration"
check_optional "NEXT_PUBLIC_SUPABASE_URL" "For Dashboard"

echo ""
echo "═══════════════════════════════════════════"
echo "  INFRASTRUCTURE (if using Terraform)"
echo "═══════════════════════════════════════════"
echo ""

check_optional "DO_TOKEN" "Digital Ocean API token"
check_optional "SSH_KEY_NAME" "SSH key name in Digital Ocean"

echo ""
echo "═══════════════════════════════════════════"
echo "  SUMMARY"
echo "═══════════════════════════════════════════"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ $ERRORS required items missing${NC}"
    echo ""
    echo "Please fill in the missing values in your .env file"
    echo "See PREREQUISITES.md for detailed instructions"
    exit 1
else
    echo -e "${GREEN}✅ All required items configured!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $WARNINGS optional items not configured${NC}"
    fi
    echo ""
    echo "You're ready to deploy! 🚀"
    exit 0
fi
