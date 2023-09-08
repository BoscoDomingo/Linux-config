# Sourced for login shells (interactive or not).
# Ensures PATH and env vars are available to non-interactive login shells
# such as those spawned by VS Code / Cursor in WSL.
[[ -r ~/.profile ]] && emulate sh -c 'source ~/.profile'
