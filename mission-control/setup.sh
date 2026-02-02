#!/bin/bash
#
# 🧠 Mission Control Setup
# Instala DeepEval y configura el Judgment System
#

set -e

echo "🧠 Setting up Mission Control with DeepEval..."

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install deepeval google-generativeai

# Create logs directory
mkdir -p logs

# Create .env template
cat > .env << 'EOF'
# DeepEval Configuration
# Use Gemini (cheaper) or OpenAI for LLM-as-Judge

# Option 1: Gemini (recommended)
GEMINI_API_KEY=your-gemini-key
GEMINI_MODEL=gemini-2.0-flash

# Option 2: OpenAI
# OPENAI_API_KEY=your-openai-key

# Judgment thresholds
CONFIDENCE_THRESHOLD_LOW=30
CONFIDENCE_THRESHOLD_HIGH=70
EOF

echo ""
echo "✅ Mission Control setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env with your API keys"
echo "2. Source the venv: source .venv/bin/activate"
echo "3. Test: python lib/evaluator.py --test"
