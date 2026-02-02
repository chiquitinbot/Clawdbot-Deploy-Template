#!/bin/bash
#
# ✅ Check local requirements
# Run this before attempting any deployment
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║     ✅ Requirements Check                ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

MISSING=0

check_required() {
    if command -v $1 &> /dev/null; then
        VERSION=$($1 --version 2>&1 | head -1)
        echo -e "${GREEN}✅ $1${NC}: $VERSION"
    else
        echo -e "${RED}❌ $1${NC}: NOT INSTALLED"
        ((MISSING++))
    fi
}

check_optional() {
    if command -v $1 &> /dev/null; then
        VERSION=$($1 --version 2>&1 | head -1)
        echo -e "${GREEN}✅ $1${NC}: $VERSION"
    else
        echo -e "${YELLOW}⚪ $1${NC}: not installed (optional)"
    fi
}

check_node_version() {
    if command -v node &> /dev/null; then
        VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
        if [ "$VERSION" -ge 22 ]; then
            echo -e "${GREEN}   Node version OK (22+)${NC}"
        else
            echo -e "${RED}   ⚠️  Node version $VERSION is too old. Need 22+${NC}"
            ((MISSING++))
        fi
    fi
}

echo -e "${BLUE}--- Required for ALL deployments ---${NC}"
check_required git
echo ""

echo -e "${BLUE}--- Required for LOCAL deployment ---${NC}"
check_required node
check_node_version
check_required npm
echo ""

echo -e "${BLUE}--- Required for VPS deployment ---${NC}"
check_required ssh
echo ""

echo -e "${BLUE}--- Optional (Terraform deployment) ---${NC}"
check_optional terraform
check_optional doctl
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✅ All requirements satisfied!${NC}"
    echo ""
    echo "You can proceed with:"
    echo "  ./scripts/bootstrap-local.sh   # Local deployment"
    echo "  ./scripts/bootstrap-vps.sh     # VPS deployment"
else
    echo -e "${RED}❌ Missing $MISSING required package(s)${NC}"
    echo ""
    echo "Install missing packages first. See REQUIREMENTS.md for instructions."
    exit 1
fi
echo ""
