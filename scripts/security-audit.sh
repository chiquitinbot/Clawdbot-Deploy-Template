#!/bin/bash
#
# 🔒 Security Audit Script
# Run this periodically to check your server's security status
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║       🔒 SECURITY AUDIT REPORT           ║"
echo "║       $(date '+%Y-%m-%d %H:%M:%S')              ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

ISSUES=0
WARNINGS=0

# Function to check and report
check_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
}

check_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((ISSUES++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    ((WARNINGS++))
}

echo -e "\n${BLUE}═══ FIREWALL ═══${NC}"

if ufw status | grep -q "Status: active"; then
    check_pass "UFW is active"
    
    # Check for dangerous open ports
    if ufw status | grep -q "8080.*ALLOW.*Anywhere"; then
        check_fail "Port 8080 is open to public (should be localhost only)"
    fi
else
    check_fail "UFW is NOT active - run: ufw enable"
fi

echo -e "\n${BLUE}═══ SSH SECURITY ═══${NC}"

if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
    check_pass "SSH password authentication disabled"
else
    check_fail "SSH password authentication is ENABLED - disable it!"
fi

if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
    check_pass "Root login disabled"
elif grep -q "^PermitRootLogin prohibit-password" /etc/ssh/sshd_config 2>/dev/null; then
    check_pass "Root login limited to key-only"
else
    check_warn "Root login with password may be enabled"
fi

echo -e "\n${BLUE}═══ FAIL2BAN ═══${NC}"

if systemctl is-active --quiet fail2ban 2>/dev/null; then
    check_pass "Fail2ban is running"
    BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
    echo "       Currently banned IPs: $BANNED"
else
    check_warn "Fail2ban not running - install with: apt install fail2ban"
fi

echo -e "\n${BLUE}═══ FILE PERMISSIONS ═══${NC}"

# Check .env file
if [ -f "$HOME/.env" ]; then
    PERMS=$(stat -c %a "$HOME/.env" 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        check_pass ".env has correct permissions (600)"
    else
        check_fail ".env has permissions $PERMS (should be 600)"
    fi
else
    echo "       .env not found in home directory"
fi

# Check SSH directory
if [ -d "$HOME/.ssh" ]; then
    SSH_PERMS=$(stat -c %a "$HOME/.ssh" 2>/dev/null)
    if [ "$SSH_PERMS" = "700" ]; then
        check_pass ".ssh directory has correct permissions (700)"
    else
        check_warn ".ssh has permissions $SSH_PERMS (should be 700)"
    fi
fi

# Check for world-readable credential files
EXPOSED=$(find $HOME -name "*.env" -o -name "*credential*" -o -name "*secret*" -o -name "cookies.json" 2>/dev/null | xargs ls -la 2>/dev/null | grep -E "^-..r..r" | wc -l)
if [ "$EXPOSED" -gt 0 ]; then
    check_fail "Found $EXPOSED credential files readable by others"
else
    check_pass "No world-readable credential files found"
fi

echo -e "\n${BLUE}═══ OPEN PORTS ═══${NC}"

echo "Listening ports:"
ss -tlnp 2>/dev/null | grep LISTEN | while read line; do
    PORT=$(echo $line | awk '{print $4}' | rev | cut -d: -f1 | rev)
    PROC=$(echo $line | awk '{print $6}' | cut -d'"' -f2)
    ADDR=$(echo $line | awk '{print $4}' | rev | cut -d: -f2- | rev)
    
    if [[ "$ADDR" == "0.0.0.0" || "$ADDR" == "*" || "$ADDR" == "[::]" ]]; then
        if [[ "$PORT" == "22" || "$PORT" == "80" || "$PORT" == "443" ]]; then
            echo -e "       ${GREEN}✓${NC} :$PORT ($PROC) - expected public"
        else
            echo -e "       ${YELLOW}!${NC} :$PORT ($PROC) - exposed to internet"
        fi
    else
        echo -e "       ${GREEN}✓${NC} $ADDR:$PORT ($PROC) - local only"
    fi
done

echo -e "\n${BLUE}═══ FAILED LOGIN ATTEMPTS (24h) ═══${NC}"

FAILED=$(grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %d')\|$(date -d yesterday '+%b %d')" | wc -l)
if [ "$FAILED" -gt 100 ]; then
    check_warn "High number of failed logins: $FAILED (consider fail2ban)"
elif [ "$FAILED" -gt 0 ]; then
    echo "       $FAILED failed login attempts (normal)"
else
    check_pass "No failed login attempts"
fi

echo -e "\n${BLUE}═══ SYSTEM UPDATES ═══${NC}"

UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
if [ "$UPDATES" -gt 10 ]; then
    check_warn "$UPDATES packages can be upgraded - run: apt upgrade"
elif [ "$UPDATES" -gt 0 ]; then
    echo "       $UPDATES packages can be upgraded"
else
    check_pass "System is up to date"
fi

# Check automatic updates
if [ -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
    if grep -q 'APT::Periodic::Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades; then
        check_pass "Automatic security updates enabled"
    else
        check_warn "Automatic updates not fully configured"
    fi
else
    check_warn "Automatic updates not configured"
fi

echo -e "\n${BLUE}═══ OPENCLAW STATUS ═══${NC}"

if command -v openclaw &> /dev/null; then
    if pgrep -f "openclaw" > /dev/null; then
        check_pass "OpenClaw gateway is running"
    else
        echo "       OpenClaw installed but not running"
    fi
else
    echo "       OpenClaw not installed"
fi

# Summary
echo -e "\n${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              SUMMARY                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"

if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All security checks passed!${NC}"
elif [ $ISSUES -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warnings - review recommended${NC}"
else
    echo -e "${RED}❌ $ISSUES critical issues found!${NC}"
    echo -e "${YELLOW}⚠️  $WARNINGS warnings${NC}"
    echo ""
    echo "Run these commands to fix critical issues:"
    echo "  ufw enable                    # Enable firewall"
    echo "  chmod 600 ~/.env              # Fix .env permissions"
    echo "  apt install fail2ban          # Install fail2ban"
fi

echo ""
