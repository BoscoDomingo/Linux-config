#!/bin/bash

# Loading text
# RED='\033[0;31m'
# echo -e "${RED}Starting tmux${NC}"

# Start tmux if not already inside a tmux session and not in VS Code nor Cursor
if command -v tmux >/dev/null 2>&1; then
	# Only needed if not using tmux plugins for this
	# if [ -z "$(ps -a | grep .tmux-resource)" ]; then
	# 	echo "Starting tmux resource monitor"
	# 	$XDG_CONFIG_HOME/tmux/.tmux-resource-monitor.sh &
	# fi

	# Debug print to confirm environment variables at the time .profile runs
	# echo "[.profile debug] TMUX=$TMUX, VSCODE_IPC_HOOK_CLI=$VSCODE_IPC_HOOK_CLI, TERM_PROGRAM=$TERM_PROGRAM" 1>&2
	# printenv 1>&2 # Debug print all environment variables

	if [ -z "$TMUX" ] && [ -z "$VSCODE_IPC_HOOK_CLI" ] && [ "$TERM_PROGRAM" != "Cursor" ] && [ "$TERM_PROGRAM" != "vscode" ] && [ "$TERM_PROGRAM" != "WarpTerminal" ]; then
		tmux a -t default -c "zsh && clear" || tmux new-session -s default -c "zsh && clear"
		# tmux send-keys -t default "zsh" C-m
		# tmux send-keys -t default "clear" C-m
	fi
fi