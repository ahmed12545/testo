#!/bin/bash

# ============================================
# Ngrok Setup + Hello World Page Hoster
# ============================================

PORT=8080

echo "========================================="
echo "  Ngrok Server Setup"
echo "========================================="

# --- Step 1: Check/Install ngrok ---
echo ""
echo "[1/4] Checking ngrok..."

if command -v ngrok &> /dev/null; then
    echo "✅ ngrok is already installed."
else
    echo "❌ ngrok not found. Installing..."

    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
      | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
      && echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
      | sudo tee /etc/apt/sources.list.d/ngrok.list \
      && sudo apt update \
      && sudo apt install ngrok -y

    if command -v ngrok &> /dev/null; then
        echo "✅ ngrok installed successfully!"
    else
        echo "❌ Failed to install ngrok. Exiting."
        exit 1
    fi
fi

# --- Step 2: Auth token ---
echo ""
echo "[2/4] Configuring ngrok..."
echo ""
echo "Get your token from: https://dashboard.ngrok.com/get-started/your-authtoken"
echo ""
read -rp "Enter your ngrok auth token: " AUTH_TOKEN

if [ -z "$AUTH_TOKEN" ]; then
    echo "❌ Token cannot be empty!"
    exit 1
fi

ngrok config add-authtoken "$AUTH_TOKEN"
echo "✅ Token configured!"

# --- Step 3: Clean port and create page ---
echo ""
echo "[3/4] Setting up web page on port $PORT..."

# Kill anything on the port (don't exit if nothing found)
PID=$(lsof -ti :$PORT 2>/dev/null || true)
if [ -n "$PID" ]; then
    echo "Killing process on port $PORT..."
    kill -9 $PID 2>/dev/null || true
    sleep 1
    echo "Port cleared."
else
    echo "Port $PORT is free."
fi

# Create the page
mkdir -p /tmp/mysite

cat > /tmp/mysite/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #1e3c72, #2a5298);
            color: white;
        }
        .box {
            text-align: center;
            padding: 40px;
            border: 2px solid rgba(255,255,255,0.3);
            border-radius: 15px;
        }
        h1 { font-size: 2.5em; }
        p { font-size: 1.2em; opacity: 0.8; }
    </style>
</head>
<body>
    <div class="box">
        <h1>✅ Hello World!</h1>
        <p>Your server is live via ngrok.</p>
        <p>Accessible from anywhere 🌍</p>
    </div>
</body>
</html>
HTML

echo "✅ Page created."

# Start python web server in background
echo "Starting web server..."
cd /tmp/mysite
python3 -m http.server $PORT &
HTTP_PID=$!
sleep 2

# Verify it started
if kill -0 $HTTP_PID 2>/dev/null; then
    echo "✅ Web server running on port $PORT (PID: $HTTP_PID)"
else
    echo "❌ Web server failed to start!"
    exit 1
fi

# Test it locally
echo "Testing locally..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT 2>/dev/null || true)
if [ "$RESPONSE" = "200" ]; then
    echo "✅ Local test passed! (HTTP 200)"
else
    echo "⚠️  Local test returned: $RESPONSE (might still work)"
fi

# --- Step 4: Start ngrok ---
echo ""
echo "[4/4] Starting ngrok tunnel..."

# Cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down..."
    kill $HTTP_PID 2>/dev/null || true
    echo "Done!"
}
trap cleanup EXIT INT TERM

echo ""
echo "========================================="
echo "  Look for the Forwarding URL below"
echo "  Copy that link to your phone!"
echo ""
echo "  Press Ctrl+C to stop everything."
echo "========================================="
echo ""

ngrok http $PORT
