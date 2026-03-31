#!/bin/bash

LOG="/tmp/bot_output.log"
SESSION="bot"

case "$1" in

  start)
    tmux kill-session -t "$SESSION" 2>/dev/null
    > "$LOG"
    tmux new-session -d -s "$SESSION" "bash /path/to/botstart.sh 2>&1 | tee $LOG"
    echo "Bot started. Now run:"
    echo "  ./bot.sh watch    - see everything"
    echo "  ./bot.sh send XX  - type something"
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
    echo "./bot.sh start   - start bot"
    echo "./bot.sh watch   - see ALL output live"
    echo "./bot.sh log     - dump full log"
    echo "./bot.sh send X  - send input"
    echo "./bot.sh stop    - kill bot"
    ;;

esac
