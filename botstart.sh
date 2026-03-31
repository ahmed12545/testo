#!/bin/bash
set -e

read -p "Enter your ngrok authtoken: " NGROK_TOKEN

mkdir -p /tmp/ngrok-test
cd /tmp/ngrok-test

cat > index.html <<EOF
<h1>Hello World</h1>
EOF

python3 -m http.server 8000 >/dev/null 2>&1 &
SERVER_PID=$!

ngrok config add-authtoken "$NGROK_TOKEN" >/dev/null 2>&1
ngrok http 8000

kill $SERVER_PID
