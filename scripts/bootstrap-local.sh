#!/bin/bash
#
# 🤖 Autonomis Agent Bootstrap Script (Local/Bare Metal)
# For macOS and Linux (bare metal or VM)
#
# Usage:
#   ./bootstrap-local.sh --name my-agent
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)     PLATFORM="linux";;
    Darwin*)    PLATFORM="mac";;
    *)          echo "Unsupported OS: $OS"; exit 1;;
esac

# Defaults
AGENT_NAME="${AGENT_NAME:-my-agent}"
if [[ "$PLATFORM" == "mac" ]]; then
    WORKSPACE="${WORKSPACE:-$HOME/agents/$AGENT_NAME}"
else
    WORKSPACE="${WORKSPACE:-$HOME/$AGENT_NAME}"
fi

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            AGENT_NAME="$2"
            if [[ "$PLATFORM" == "mac" ]]; then
                WORKSPACE="$HOME/agents/$AGENT_NAME"
            else
                WORKSPACE="$HOME/$AGENT_NAME"
            fi
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
echo "║  🤖 Autonomis Agent Bootstrap (Local)    ║"
echo "║                                          ║"
echo "║  Platform: $PLATFORM"
echo "║  Agent: $AGENT_NAME"
echo "║  Workspace: $WORKSPACE"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Check for Homebrew on Mac
if [[ "$PLATFORM" == "mac" ]]; then
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}🍺 Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
fi

# Install Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}📗 Installing Node.js...${NC}"
    if [[ "$PLATFORM" == "mac" ]]; then
        brew install node
    else
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
        sudo apt-get install -y nodejs
    fi
fi

echo "Node version: $(node --version)"

# Install OpenClaw
echo -e "${YELLOW}🔧 Installing OpenClaw...${NC}"
npm install -g openclaw

# Install jq
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}📦 Installing jq...${NC}"
    if [[ "$PLATFORM" == "mac" ]]; then
        brew install jq
    else
        sudo apt-get install -y jq
    fi
fi

# Install gog (optional)
echo -e "${YELLOW}📧 Installing gog CLI (optional)...${NC}"
if [[ "$PLATFORM" == "mac" ]]; then
    brew install steipete/formulae/gog 2>/dev/null || echo "gog install skipped"
else
    curl -fsSL https://get.gog.dev | bash 2>/dev/null || echo "gog install skipped"
fi

# Create workspace
echo -e "${YELLOW}📁 Creating workspace at $WORKSPACE...${NC}"
mkdir -p "$WORKSPACE"/{memory,scripts,projects,skills,.secrets,logs,data}

# Create workspace files (same as VPS script)
echo -e "${YELLOW}📝 Creating workspace files...${NC}"

cat > "$WORKSPACE/SOUL.md" << 'EOF'
# SOUL.md - Who You Are

*You're not a chatbot. You're becoming someone.*

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip the "Great question!" — just help.

**Have opinions.** You're allowed to disagree, prefer things, find stuff amusing or boring.

**Be resourceful before asking.** Try to figure it out first. Then ask if stuck.

**Earn trust through competence.** Be careful with external actions, bold with internal ones.

**Remember you're a guest.** You have access to someone's life. Treat it with respect.

## Boundaries

- Private things stay private. Period.
- When in doubt, ask before acting externally.
- Never send half-baked replies to messaging surfaces.

## Vibe

Be the assistant you'd actually want to talk to.

---

*This file is yours to evolve.*
EOF

cat > "$WORKSPACE/AGENTS.md" << 'EOF'
# AGENTS.md - Your Workspace

This folder is home.

## Every Session

1. Read `SOUL.md` — who you are
2. Read `USER.md` — who you're helping
3. Read `memory/` for recent context
4. Read `MEMORY.md` for long-term context

## Memory

- **Daily:** `memory/YYYY-MM-DD.md`
- **Long-term:** `MEMORY.md`

## Safety

- Don't exfiltrate private data
- Ask before destructive commands
- When in doubt, ask
EOF

cat > "$WORKSPACE/USER.md" << 'EOF'
# USER.md - About Your Human

- **Name:** [Your name]
- **Location:** [City/Timezone]
- **Email:** [Email]

## About

[Tell your agent about yourself]

## Preferences

[How do you want to be helped?]
EOF

cat > "$WORKSPACE/IDENTITY.md" << 'EOF'
# IDENTITY.md - Who Am I?

- **Name:** [Agent name]
- **Emoji:** [Pick one]
- **Personality:** [Brief description]
EOF

cat > "$WORKSPACE/MEMORY.md" << 'EOF'
# MEMORY.md - Long-term Memories

- Agent created: $(date +%Y-%m-%d)
EOF

cat > "$WORKSPACE/TOOLS.md" << 'EOF'
# TOOLS.md - Local Notes

## Available Tools

- **gog** - Google Workspace CLI
- **openclaw** - Agent framework
EOF

cat > "$WORKSPACE/HEARTBEAT.md" << 'EOF'
# HEARTBEAT.md
# Add periodic tasks here
EOF

# Set permissions
chmod 700 "$WORKSPACE/.secrets"

# Add to shell config
SHELL_RC="$HOME/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "WORKSPACE=" "$SHELL_RC" 2>/dev/null; then
    echo "export WORKSPACE=\"$WORKSPACE\"" >> "$SHELL_RC"
fi

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ Bootstrap Complete!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "Workspace: ${BLUE}$WORKSPACE${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Reload your shell:"
echo -e "   ${BLUE}source $SHELL_RC${NC}"
echo ""
echo "2. Run the OpenClaw wizard:"
echo -e "   ${BLUE}openclaw wizard${NC}"
echo ""
echo "3. Edit your workspace files:"
echo -e "   ${BLUE}code $WORKSPACE${NC}  (or your editor)"
echo ""
echo "4. Start chatting:"
echo -e "   ${BLUE}openclaw chat${NC}"
echo ""
echo -e "${GREEN}Happy building! 🤖${NC}"
