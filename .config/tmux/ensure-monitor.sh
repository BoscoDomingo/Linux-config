#!/bin/bash

# Ensure monitor window exists in current tmux session
# This script checks if a window named "mon" exists and creates it if not

if [ -z "$TMUX" ]; then
    exit 0
fi

# Only create monitor window for "default" session
SESSION_NAME=$(tmux display-message -p '#S')
if [ "$SESSION_NAME" = "default" ]; then
    # Create window in detached mode if not exists and start btm
    if ! tmux list-windows -t "$SESSION_NAME" | grep -q "mon"; then
        tmux new-window -d -t "$SESSION_NAME" -n "mon"
        tmux send-keys -t "$SESSION_NAME":mon "clear && btm" C-m
        exit 0
    fi

    # Check if btm is running in the mon window, if not start it
    if ! tmux list-panes -t "$SESSION_NAME":mon -F "#{pane_current_command}" | grep -q "btm"; then
        tmux send-keys -t "$SESSION_NAME":mon "clear && btm" C-m
    fi

    # Move monitor window to the end (highest index)
    # using swap-window and returning focus to the second-to-last window
    END_INDEX=$(tmux list-windows -t "$SESSION_NAME" -F "#{window_index}" | sort -nr | head -1)
    MON_INDEX=$(tmux list-windows -t "$SESSION_NAME" -F "#{window_index}:#{window_name}" | grep "mon" | cut -d: -f1)
    if [ "$MON_INDEX" != "$END_INDEX" ] && [ -n "$MON_INDEX" ] && [ -n "$END_INDEX" ]; then
        tmux swap-window -s "$SESSION_NAME":mon -t "$SESSION_NAME":$END_INDEX 2>/dev/null || true
        tmux select-window -t "$SESSION_NAME":$((END_INDEX-1))
    fi
	tmux set-window-option -t "$SESSION_NAME:$END_INDEX" window-status-style bg=colour240,fg=white
fi