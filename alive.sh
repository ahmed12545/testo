#!/bin/bash

LOG="/tmp/bot_output.log"
SESSION="bot"

case "$1" in

  watch)
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "Bot is not running."
        exit 1
    fi
    tail -f "$LOG"
    ;;

  log)
    if [ -f "$LOG" ]; then
        cat "$LOG"
    else
        echo "No log file found."
    fi
    ;;

  links)
    if [ -f "$LOG" ]; then
        grep -Eo 'https?://[^ ]+' "$LOG"
    else
        echo "No log file found."
    fi
    ;;

  send)
    shift
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "Bot is not running."
        exit 1
    fi
    tmux send-keys -t "$SESSION" "$*" Enter
    echo "Sent: $*"
    sleep 1
    tail -5 "$LOG"
    ;;

  ctrlc)
    tmux send-keys -t "$SESSION" C-c
    echo "Sent Ctrl+C"
    ;;

  status)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "Bot tmux session: RUNNING"
        echo ""
        echo "Processes:"
        ps aux | grep -E 'runner.py|app.py|ngrok' | grep -v grep
    else
        echo "Bot tmux session: NOT RUNNING"
    fi
    ;;

  stop)
    tmux kill-session -t "$SESSION" 2>/dev/null
    echo "Bot killed."
    # Also kill any leftover processes
    pkill -f "runner.py" 2>/dev/null
    pkill -f "app.py" 2>/dev/null
    pkill -f "ngrok" 2>/dev/null
    echo "All processes cleaned up."
    ;;

  *)
    echo "Usage:"
    echo "  ./alive.sh watch    - see engine output live"
    echo "  ./alive.sh log      - dump full log"
    echo "  ./alive.sh links    - extract all URLs"
    echo "  ./alive.sh send X   - send input to bot"
    echo "  ./alive.sh ctrlc    - send Ctrl+C to bot"
    echo "  ./alive.sh status   - check if bot is running"
    echo "  ./alive.sh stop     - kill everything"
    ;;

esac
