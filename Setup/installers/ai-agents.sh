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

# MARK: - Gentle-AI CLI
read -p "Install Gentle-AI CLI via Homebrew? (Y/n): " install_gentle_ai
if [ "$install_gentle_ai" != "n" ]; then
	if command -v brew >/dev/null 2>&1; then
		# Gentle-AI is user-global agent workflow tooling; Brew keeps updates and rollback manageable.
		brew tap Gentleman-Programming/homebrew-tap
		if brew list --formula gentle-ai >/dev/null 2>&1; then
			echo "Gentle-AI is already installed. Checking for upgrades..."
			if brew outdated --quiet gentle-ai | grep -qx "gentle-ai"; then
				brew upgrade gentle-ai
			else
				echo "Gentle-AI is already up to date."
			fi
		else
			brew install gentle-ai
		fi
		hash -r 2>/dev/null || true
		gentle-ai version || true
	else
		echo "Homebrew is not available. Skipping Gentle-AI CLI installation."
	fi
else
	echo "Skipping Gentle-AI CLI installation."
fi

# MARK: - Gentle-AI Pi Integration
read -p "Configure Gentle-AI for Pi? (Y/n): " configure_gentle_ai_pi
if [ "$configure_gentle_ai_pi" != "n" ]; then
	if command -v gentle-ai >/dev/null 2>&1 && command -v pi >/dev/null 2>&1; then
		# Preview Pi package/config changes before installing extensions with agent-level privileges.
		gentle-ai install --agent pi --dry-run
		read -p "Apply this Gentle-AI Pi setup? (y/N): " apply_gentle_ai_pi
		if [ "$apply_gentle_ai_pi" = "y" ]; then
			gentle-ai install --agent pi
		else
			echo "Skipping Gentle-AI Pi setup after dry run."
		fi
	else
		echo "gentle-ai or pi is missing from PATH. Skipping Gentle-AI Pi setup."
	fi
else
	echo "Skipping Gentle-AI Pi setup."
fi
