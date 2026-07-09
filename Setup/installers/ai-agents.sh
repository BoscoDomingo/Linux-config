# MARK: - AI Agent Setup
printf "\n=== AI Agent Setup ===\n"

# MARK: - AI Agent Safety Guards
read -p "Install AI-agent-only Jujutsu approval guards? (Y/n): " install_ai_agent_guards
if [ "$install_ai_agent_guards" != "n" ]; then
	# Merge provider hook/permission config without wrapping the human `jj` command.
	python3 "$CURRENT_DIR/AI/agent-guards/install.py"
else
	echo "Skipping AI agent safety guard installation."
fi

# MARK: - Engram (agent memory) — register with autodiscovered coding agents
read -p "Set up engram for installed coding agents? (Y/n): " setup_engram
if [ "$setup_engram" != "n" ]; then
	# engram binary comes from mise; this registers it with each agent present.
	bash "$CURRENT_DIR/scripts/engram-setup"
else
	echo "Skipping engram setup."
fi
