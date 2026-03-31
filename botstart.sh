#!/bin/bash

# ============================================
# Simple Web Page Hoster on Your Server
# ============================================

PORT=8080

echo "========================================="
echo "  Simple Server Page Hoster"
echo "========================================="

# Step 1: Kill anything running on the port
echo ""
echo "[1/3] Cleaning port $PORT..."

# Find and kill any process using the port
PID=$(lsof -ti :$PORT 2>/dev/null)
if [ -n "$PID" ]; then
    echo "Killing process(es) on port $PORT: $PID"
    kill -9 $PID 2>/dev/null
    sleep 1
    echo "Port $PORT cleared."
else
    echo "Port $PORT is already free."
fi

# Step 2: Create the page
echo ""
echo "[2/3] Creating web page..."

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
        <h1>✅ It Works!</h1>
        <p>Your server is live and accessible.</p>
    </div>
</body>
</html>
HTML

# Step 3: Get server IP and start serving
echo ""
echo "[3/3] Starting server..."

# Get the server's IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "========================================="
echo ""
echo "  ✅ Server is running!"
echo ""
echo "  Open this on your phone:"
echo ""
echo "  👉  http://$SERVER_IP:$PORT"
echo ""
echo "========================================="
echo ""
echo "Press Ctrl+C to stop the server."
echo ""

# Start serving
cd /tmp/mysite
python3 -m http.server $PORT
