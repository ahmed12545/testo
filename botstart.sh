#!/bin/bash

echo "=================================================="
echo "  XRP Execution Engine — Setup & Run"
echo "=================================================="
echo ""

# ── Base directory = where this script lives ────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR"
echo "  Base directory: $BASE_DIR"

# ── Credentials ─────────────────────────────────────────
read -p "  GitHub token: " GITHUB_TOKEN
read -p "  GitHub username: " GITHUB_USER
read -p "  Ngrok auth token: " NGROK_TOKEN
echo ""

# ── Check/Install system packages ──────────────────────
echo "  Checking system packages..."

# Get Python version
PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}' | cut -d. -f1,2 || true)

if [ -z "$PYTHON_VERSION" ]; then
    echo "  ❌ Python3 not found. Installing..."
    sudo apt update
    sudo apt install python3 -y
    PYTHON_VERSION=$(python3 --version | awk '{print $2}' | cut -d. -f1,2)
fi
echo "  ✓ Python $PYTHON_VERSION found"

# Check and install python3-venv
if ! dpkg -l | grep -q "python3-venv\|python${PYTHON_VERSION}-venv"; then
    echo "  ❌ python3-venv not found. Installing..."
    sudo apt update
    sudo apt install python3-venv "python${PYTHON_VERSION}-venv" -y 2>/dev/null || sudo apt install python3-venv -y
    echo "  ✓ python3-venv installed"
else
    echo "  ✓ python3-venv found"
fi

# Check and install python3-pip
if ! command -v pip3 &> /dev/null; then
    echo "  ❌ pip3 not found. Installing..."
    sudo apt update
    sudo apt install python3-pip -y
    echo "  ✓ pip3 installed"
else
    echo "  ✓ pip3 found"
fi

# Check and install python3-dev (needed for some packages like numpy)
if ! dpkg -l | grep -q "python3-dev\|python${PYTHON_VERSION}-dev"; then
    echo "  ❌ python3-dev not found. Installing..."
    sudo apt install python3-dev "python${PYTHON_VERSION}-dev" -y 2>/dev/null || sudo apt install python3-dev -y
    echo "  ✓ python3-dev installed"
else
    echo "  ✓ python3-dev found"
fi

# Check and install build-essential (needed for compiling some pip packages)
if ! dpkg -l | grep -q "build-essential"; then
    echo "  ❌ build-essential not found. Installing..."
    sudo apt install build-essential -y
    echo "  ✓ build-essential installed"
else
    echo "  ✓ build-essential found"
fi

# Check and install curl
if ! command -v curl &> /dev/null; then
    echo "  ❌ curl not found. Installing..."
    sudo apt install curl -y
    echo "  ✓ curl installed"
else
    echo "  ✓ curl found"
fi

# Check and install lsof
if ! command -v lsof &> /dev/null; then
    echo "  ❌ lsof not found. Installing..."
    sudo apt install lsof -y
    echo "  ✓ lsof installed"
else
    echo "  ✓ lsof found"
fi

# Check and install git
if ! command -v git &> /dev/null; then
    echo "  ❌ git not found. Installing..."
    sudo apt install git -y
    echo "  ✓ git installed"
else
    echo "  ✓ git found"
fi

echo ""

# ── Check/Install ngrok ────────────────────────────────
echo "  Checking ngrok..."

if command -v ngrok &> /dev/null; then
    echo "  ✓ ngrok is already installed"
else
    echo "  Installing ngrok..."
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
      | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
      && echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
      | sudo tee /etc/apt/sources.list.d/ngrok.list \
      && sudo apt update \
      && sudo apt install ngrok -y

    if command -v ngrok &> /dev/null; then
        echo "  ✓ ngrok installed successfully"
    else
        echo "  ❌ Failed to install ngrok. Exiting."
        exit 1
    fi
fi

ngrok config add-authtoken "$NGROK_TOKEN"
echo "  ✓ ngrok configured"
echo ""

cd "$BASE_DIR"

# ── Clone repos ─────────────────────────────────────────
echo "  Cloning repositories..."

if [ -d "$BASE_DIR/xrp-feature-engine" ]; then
    echo "  xrp-feature-engine exists, pulling..."
    cd "$BASE_DIR/xrp-feature-engine" && git pull -q && cd "$BASE_DIR"
else
    git clone -q "https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/xrp-feature-engine.git" "$BASE_DIR/xrp-feature-engine"
fi
echo "  ✓ xrp-feature-engine"

if [ -d "$BASE_DIR/xrp-execution-engine" ]; then
    echo "  xrp-execution-engine exists, pulling..."
    cd "$BASE_DIR/xrp-execution-engine" && git pull -q && cd "$BASE_DIR"
else
    git clone -q "https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/xrp-execution-engine.git" "$BASE_DIR/xrp-execution-engine"
fi
echo "  ✓ xrp-execution-engine"

# ── Virtual environment ─────────────────────────────────
echo ""
echo "  Setting up virtual environment..."

VENV_DIR="$BASE_DIR/venv"

# If venv exists but is broken, remove it and recreate
if [ -d "$VENV_DIR" ]; then
    if [ ! -f "$VENV_DIR/bin/activate" ] || [ ! -f "$VENV_DIR/bin/python" ]; then
        echo "  ⚠️ Existing venv is broken. Removing..."
        rm -rf "$VENV_DIR"
    fi
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "  Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "  ❌ Failed to create venv. Trying with --without-pip..."
        python3 -m venv --without-pip "$VENV_DIR"
        source "$VENV_DIR/bin/activate"
        curl -sS https://bootstrap.pypa.io/get-pip.py | python
    fi
    echo "  ✓ Created virtual environment"
else
    echo "  ✓ Virtual environment exists"
fi

# Verify activation works
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "  ❌ venv activate script not found. Something is wrong."
    echo "  Trying to reinstall python3-venv..."
    sudo apt install --reinstall python3-venv "python${PYTHON_VERSION}-venv" -y 2>/dev/null
    rm -rf "$VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Verify python is from venv
WHICH_PYTHON=$(which python)
if [[ "$WHICH_PYTHON" == *"$VENV_DIR"* ]]; then
    echo "  ✓ Activated: $WHICH_PYTHON"
else
    echo "  ⚠️ Warning: python might not be from venv: $WHICH_PYTHON"
    echo "  Using explicit venv path instead..."
    export PATH="$VENV_DIR/bin:$PATH"
    echo "  ✓ Forced venv PATH: $(which python)"
fi

# ── Install dependencies ────────────────────────────────
echo ""
echo "  Installing dependencies..."

pip install --upgrade pip setuptools wheel -q 2>/dev/null
pip install -e "$BASE_DIR/xrp-feature-engine" -q 2>/dev/null
pip install -r "$BASE_DIR/xrp-execution-engine/requirements.txt" -q 2>/dev/null
echo "  ✓ All dependencies installed"

# Quick sanity check
echo ""
echo "  Verifying key packages..."
python -c "import numpy; print('  ✓ numpy', numpy.__version__)" 2>/dev/null || echo "  ❌ numpy missing"
python -c "import flask; print('  ✓ flask', flask.__version__)" 2>/dev/null || echo "  ❌ flask missing"
python -c "import pandas; print('  ✓ pandas', pandas.__version__)" 2>/dev/null || echo "  ❌ pandas missing"

# ── Check model weights ────────────────────────────────
echo ""
echo "  Checking model weights..."

MODELS_DIR="$BASE_DIR/xrp-execution-engine/models"
ALL_GOOD=1

for f in catboost_balanced.pkl lgbm_conservative.pkl xgb_balanced.pkl feature_columns.json; do
    if [ -f "$MODELS_DIR/$f" ]; then
        SIZE=$(du -h "$MODELS_DIR/$f" | cut -f1)
        echo "  ✓ $f ($SIZE)"
    else
        echo "  🔴 MISSING: $f"
        ALL_GOOD=0
    fi
done

if [ "$ALL_GOOD" -eq 0 ]; then
    echo ""
    echo "  ⚠️ Some weights missing. Run Kaggle training cell first."
fi

# ── Set environment ─────────────────────────────────────
export FEATURE_ENGINE_PATH="$BASE_DIR/xrp-feature-engine"

# ── Start web dashboard silently ────────────────────────
echo ""
echo "  Starting dashboard..."

cd "$BASE_DIR/xrp-execution-engine/web"
python app.py > /dev/null 2>&1 &
WEB_PID=$!
cd "$BASE_DIR"
sleep 2
echo "  ✓ Dashboard running (PID: $WEB_PID)"

# ── Start ngrok tunnel ──────────────────────────────────
echo ""
echo "  Starting ngrok tunnel..."

WEB_PORT=$(python -c "
import json, os
p = os.path.join('$BASE_DIR', 'xrp-execution-engine', 'config', 'settings.json')
with open(p) as f: print(json.load(f).get('web_port', 8000))
" 2>/dev/null || echo "8000")

ngrok http $WEB_PORT --log=stdout > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!
sleep 3

# Get the public URL from ngrok API
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data['tunnels'][0]['public_url'])
except:
    print('')
" 2>/dev/null || true)

if [ -n "$NGROK_URL" ]; then
    echo "  ✓ ngrok tunnel active (PID: $NGROK_PID)"
else
    NGROK_URL="(could not detect — check http://localhost:4040)"
    echo "  ⚠️ ngrok started but URL not detected yet"
fi

# ── Summary ─────────────────────────────────────────────
echo ""
echo "=================================================="
echo "  SETUP COMPLETE"
echo "=================================================="
echo "  Directory:   $BASE_DIR"
echo "  Local:       http://localhost:$WEB_PORT"
echo "  Public:      $NGROK_URL"
echo "  Password:    $(cat $BASE_DIR/xrp-execution-engine/config/password.txt)"
echo "=================================================="
echo ""
echo "  👉 Open the Public URL on your phone!"
echo ""
echo "  Starting engine..."
echo ""

# ── Start engine (only engine output visible) ───────────
echo "=================================================="
echo "  ENGINE OUTPUT"
echo "=================================================="
echo ""

cd "$BASE_DIR/xrp-execution-engine/engine"

cleanup() {
    echo ""
    echo "  Shutting down..."
    kill $WEB_PID 2>/dev/null
    kill $NGROK_PID 2>/dev/null
    echo "  ✓ Dashboard stopped"
    echo "  ✓ Ngrok stopped"
    echo "  Logs: $BASE_DIR/xrp-execution-engine/logs/"
    exit 0
}

trap cleanup INT TERM

python runner.py

cleanup
