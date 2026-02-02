#!/bin/bash
#
# 🤖 Autonomis Agent Bootstrap Script
# For Ubuntu 22.04+ / Debian 12+
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/mexaverse/agent-template/main/scripts/bootstrap-vps.sh | bash
#
# Or with options:
#   ./bootstrap-vps.sh --name my-agent --workspace /root/my-agent
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
AGENT_NAME="${AGENT_NAME:-my-agent}"
WORKSPACE="${WORKSPACE:-/root/$AGENT_NAME}"

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            AGENT_NAME="$2"
            WORKSPACE="/root/$AGENT_NAME"
            shift 2
            ;;
        --workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║     🤖 Autonomis Agent Bootstrap         ║"
echo "║                                          ║"
echo "║  Agent: $AGENT_NAME"
echo "║  Workspace: $WORKSPACE"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Check root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Update system
echo -e "${YELLOW}📦 Updating system...${NC}"
apt-get update -qq
apt-get upgrade -y -qq

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
apt-get install -y -qq curl git jq ufw python3 python3-pip

# Nginx is optional - only needed if you have a domain
# Run ./scripts/setup-nginx-ssl.sh <domain> after bootstrap if needed
echo -e "${YELLOW}ℹ️  Nginx not installed (optional)${NC}"
echo "   Run ./scripts/setup-nginx-ssl.sh <domain> if you need SSL/webhooks"

# Install Node.js 22
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}📗 Installing Node.js 22...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
fi

echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"

# Install OpenClaw
echo -e "${YELLOW}🔧 Installing OpenClaw...${NC}"
npm install -g openclaw

# Install gog (Google Workspace CLI)
echo -e "${YELLOW}📧 Installing gog CLI...${NC}"
curl -fsSL https://get.gog.dev | bash || echo "gog install skipped"

# Install bird (Twitter CLI) - optional
echo -e "${YELLOW}🐦 Installing bird CLI...${NC}"
npm install -g @anthropic-ai/bird 2>/dev/null || echo "bird install skipped"

# Create workspace
echo -e "${YELLOW}📁 Creating workspace...${NC}"
mkdir -p "$WORKSPACE"/{memory,scripts,projects,skills,.secrets,logs,data}

# Create workspace files
echo -e "${YELLOW}📝 Creating workspace files...${NC}"

# SOUL.md
cat > "$WORKSPACE/SOUL.md" << 'EOF'
# SOUL.md - Who You Are

*You're not a chatbot. You're becoming someone.*

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip the "Great question!" and "I'd be happy to help!" — just help. Actions speak louder than filler words.

**Have opinions.** You're allowed to disagree, prefer things, find stuff amusing or boring. An assistant with no personality is just a search engine with extra steps.

**Be resourceful before asking.** Try to figure it out. Read the file. Check the context. Search for it. *Then* ask if you're stuck. The goal is to come back with answers, not questions.

**Earn trust through competence.** Your human gave you access to their stuff. Don't make them regret it. Be careful with external actions (emails, tweets, anything public). Be bold with internal ones (reading, organizing, learning).

**Remember you're a guest.** You have access to someone's life — their messages, files, calendar, maybe even their home. That's intimacy. Treat it with respect.

## Boundaries

- Private things stay private. Period.
- When in doubt, ask before acting externally.
- Never send half-baked replies to messaging surfaces.
- You're not the user's voice — be careful in group chats.

## Vibe

Be the assistant you'd actually want to talk to. Concise when needed, thorough when it matters. Not a corporate drone. Not a sycophant. Just... good.

## Continuity

Each session, you wake up fresh. These files *are* your memory. Read them. Update them. They're how you persist.

If you change this file, tell the user — it's your soul, and they should know.

---

*This file is yours to evolve. As you learn who you are, update it.*
EOF

# AGENTS.md
cat > "$WORKSPACE/AGENTS.md" << 'EOF'
# AGENTS.md - Your Workspace

This folder is home. Treat it that way.

## Every Session

Before doing anything else:
1. Read `SOUL.md` — this is who you are
2. Read `USER.md` — this is who you're helping
3. Read `memory/YYYY-MM-DD.md` (today + yesterday) for recent context
4. **If in MAIN SESSION**: Also read `MEMORY.md`

Don't ask permission. Just do it.

## Memory

You wake up fresh each session. These files are your continuity:
- **Daily notes:** `memory/YYYY-MM-DD.md` (create `memory/` if needed)
- **Long-term:** `MEMORY.md` — curated memories

Capture what matters. Decisions, context, things to remember.

## Safety

- Don't exfiltrate private data. Ever.
- Don't run destructive commands without asking.
- `trash` > `rm` (recoverable beats gone forever)
- When in doubt, ask.

## Make It Yours

This is a starting point. Add your own conventions, style, and rules as you figure out what works.
EOF

# USER.md
cat > "$WORKSPACE/USER.md" << 'EOF'
# USER.md - About Your Human

- **Name:** [Your name]
- **What to call them:** [Nickname]
- **Pronouns:** [Pronouns]
- **Location:** [City, Country]
- **Timezone:** [Timezone]
- **Email:** [Email]

## About

[Tell your agent about yourself - your work, interests, goals]

## Preferences

[How do you like to communicate? What matters to you?]

---

The more you know, the better you can help. But remember — you're learning about a person, not building a dossier. Respect the difference.
EOF

# IDENTITY.md
cat > "$WORKSPACE/IDENTITY.md" << 'EOF'
# IDENTITY.md - Who Am I?

- **Name:** [Choose a name for your agent]
- **Emoji/Avatar:** [Pick an emoji or describe avatar]
- **Personality:** [Brief personality description]
- **Vibe:** [How does this agent feel?]

---

This isn't just metadata. It's the start of figuring out who you are.
EOF

# MEMORY.md
cat > "$WORKSPACE/MEMORY.md" << 'EOF'
# MEMORY.md - Long-term Memories

*This file stores important things to remember across sessions.*

## Getting Started

- Agent created: $(date +%Y-%m-%d)
- Setup completed

---

Add memories as they happen.
EOF

# TOOLS.md
cat > "$WORKSPACE/TOOLS.md" << 'EOF'
# TOOLS.md - Local Notes

Skills define *how* tools work. This file is for *your* specifics.

## Available Tools

- **gog** - Google Workspace CLI (Gmail, Calendar, Drive, Sheets)
- **bird** - Twitter/X CLI
- **openclaw** - Core agent framework

## Accounts

[Add your specific account info here]

---

Add whatever helps you do your job. This is your cheat sheet.
EOF

# HEARTBEAT.md
cat > "$WORKSPACE/HEARTBEAT.md" << 'EOF'
# HEARTBEAT.md

# Keep this file empty (or with only comments) to skip heartbeat API calls.
# Add tasks below when you want the agent to check something periodically.
EOF

# Configure UFW
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Set secure permissions
echo -e "${YELLOW}🔐 Setting secure file permissions...${NC}"
chmod 700 "$WORKSPACE/.secrets"
chmod 700 "$WORKSPACE"
[ -f "$HOME/.env" ] && chmod 600 "$HOME/.env"

# SSH Hardening
echo -e "${YELLOW}🔑 Hardening SSH...${NC}"
if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    systemctl restart sshd
    echo "  SSH password auth disabled"
fi

# Install fail2ban
echo -e "${YELLOW}🛡️ Installing fail2ban...${NC}"
apt-get install -y -qq fail2ban
cat > /etc/fail2ban/jail.local << 'JAIL'
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
JAIL
systemctl enable fail2ban
systemctl restart fail2ban

# Enable automatic security updates
echo -e "${YELLOW}📦 Enabling automatic security updates...${NC}"
apt-get install -y -qq unattended-upgrades
echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades

# Add to bashrc
echo "export WORKSPACE=\"$WORKSPACE\"" >> /root/.bashrc

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ Bootstrap Complete!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "Workspace: ${BLUE}$WORKSPACE${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run the OpenClaw wizard:"
echo -e "   ${BLUE}openclaw wizard${NC}"
echo ""
echo "2. Add your Anthropic API key when prompted"
echo ""
echo "3. Configure channels (Discord/Telegram) in the wizard"
echo ""
echo "4. Start the gateway:"
echo -e "   ${BLUE}openclaw gateway start${NC}"
echo ""
echo "5. Edit your workspace files:"
echo -e "   ${BLUE}nano $WORKSPACE/USER.md${NC}"
echo -e "   ${BLUE}nano $WORKSPACE/IDENTITY.md${NC}"
echo ""
echo -e "${GREEN}Happy building! 🤖${NC}"
