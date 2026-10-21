# Bash login shells use the shared non-interactive environment layer; .profile
# then sources .bashrc for interactive login shells when appropriate.
[ -r "$HOME/.profile" ] && . "$HOME/.profile"
