# MARK: - AI Agent Safety Guards
printf "\n=== AI Agent Safety Guards ===\n"
read -p "Install AI-agent-only Jujutsu approval guards? (Y/n): " install_ai_agent_guards
if [ "$install_ai_agent_guards" != "n" ]; then
	# Merge provider hook/permission config without wrapping the human `jj` command.
	python3 "$CURRENT_DIR/AI/agent-guards/install"
else
	echo "Skipping AI agent safety guard installation."
fi
