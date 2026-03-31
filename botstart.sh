#!/bin/bash
set -e

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

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    echo "  ✓ Created virtual environment"
else
    echo "  ✓ Virtual environment exists"
fi

source "$VENV_DIR/bin/activate"
echo "  ✓ Activated: $(which python)"

# ── Install dependencies ────────────────────────────────
echo ""
echo "  Installing dependencies..."

pip install --upgrade pip setuptools wheel -q 2>/dev/null
pip install -e "$BASE_DIR/xrp-feature-engine" -q 2>/dev/null
pip install -r "$BASE_DIR/xrp-execution-engine/requirements.txt" -q 2>/dev/null
echo "  ✓ All dependencies installed"

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

# ── Summary ─────────────────────────────────────────────
echo ""
echo "=================================================="
echo "  SETUP COMPLETE"
echo "=================================================="
echo "  Directory:   $BASE_DIR"
echo "  Dashboard:   http://localhost:8000"
echo "  Password:    $(cat $BASE_DIR/xrp-execution-engine/config/password.txt)"
echo "=================================================="
echo ""
echo "  Starting..."
echo ""

# ── Start web dashboard silently ────────────────────────
cd "$BASE_DIR/xrp-execution-engine/web"
python app.py > /dev/null 2>&1 &
WEB_PID=$!
cd "$BASE_DIR"
echo "  ✓ Dashboard running (PID: $WEB_PID)"
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
    echo "  ✓ Dashboard stopped"
    echo "  Logs: $BASE_DIR/xrp-execution-engine/logs/"
    exit 0
}

trap cleanup INT TERM

python runner.py

cleanup
