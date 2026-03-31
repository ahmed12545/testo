#!/bin/bash

LOG="/tmp/bot_output.log"
SESSION="bot"
DIR="$(cd "$(dirname "$0")" && pwd)"

case "$1" in

  start)
    tmux kill-session -t "$SESSION" 2>/dev/null
    > "$LOG"
    tmux new-session -d -s "$SESSION" "cd $DIR && bash ./botstart.sh 2>&1 | tee $LOG"
    echo "Bot started. Now run:"
    echo "  ./alive.sh watch    - see everything"
    echo "  ./alive.sh send XX  - type something"
    ;;

  send)
    shift
    tmux send-keys -t "$SESSION" "$*" Enter
    ;;

  watch)
    tail -f "$LOG"
    ;;

  log)
    cat "$LOG"
    ;;

  stop)
    tmux kill-session -t "$SESSION"
    echo "Bot killed."
    ;;

  *)
    echo "./alive.sh start   - start bot"
    echo "./alive.sh watch   - see ALL output live"
    echo "./alive.sh log     - dump full log"
    echo "./alive.sh send X  - send input"
    echo "./alive.sh stop    - kill bot"
    ;;

esac
