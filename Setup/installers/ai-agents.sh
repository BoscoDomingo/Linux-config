# MARK: - AI Agent Setup
printf "\n=== AI Agent Setup ===\n"

# Keep Homebrew available when this installer is run after package-manager setup.
HOMEBREW_BIN="${HOMEBREW_BIN:-/home/linuxbrew/.linuxbrew/bin/brew}"
if ! command -v brew >/dev/null 2>&1 && [ -x "$HOMEBREW_BIN" ]; then
	eval "$("$HOMEBREW_BIN" shellenv)"
fi

# MARK: - AI Agent Safety Guards
read -p "Install AI-agent-only Jujutsu approval guards? (Y/n): " install_ai_agent_guards
if [ "$install_ai_agent_guards" != "n" ]; then
	# Merge provider hook/permission config without wrapping the human `jj` command.
	python3 "$CURRENT_DIR/AI/agent-guards/install.py"
else
	echo "Skipping AI agent safety guard installation."
fi
