# SSH notes (JJ/Git signing)

This folder only tracks SSH client config used by this dotfiles repo.

## Why a wrapper is needed

- By default, `jj` does not reliably surface SSH key passphrase prompts the same way Git does.
- For SSH commit signing, `jj` calls the configured signing program directly.
- The `ssh-sign` wrapper ensures the signing key is present in the SSH agent before calling `ssh-keygen`.
- If the key is not loaded, the wrapper runs `ssh-add` and prompts once (then agent cache is reused).

## Wrapper behavior

- Checks whether the exact key from `~/.ssh/id_ed25519.pub` is already loaded.
- Starts an agent if none is reachable.
- Adds `~/.ssh/id_ed25519` only when missing.
- Uses `/dev/tty` for interactive passphrase prompts when available.

## Related files

- `.ssh/config` -> `AddKeysToAgent yes`
- `.profile` -> stable `SSH_AUTH_SOCK` (`~/.ssh/agent/agent.sock`) + agent startup logic
- `.config/jj/config.toml` -> `signing.backend = "ssh"`, `backends.ssh.program = "ssh-sign"`
- `scripts/ssh-sign` -> wrapper script in this repo (symlinked to `~/.local/bin/ssh-sign`)

## Quick checks

```sh
# Confirm jj is configured to use the wrapper
jj config list | rg '^signing\.backends\.ssh\.program'

# Confirm your key/agent state
ssh-add -L
ssh-add -l
echo "$SSH_AUTH_SOCK"

# Smoke-test the wrapper directly
tmp=$(mktemp) && printf test > "$tmp" && ssh-sign -Y sign -f ~/.ssh/id_ed25519.pub -n git "$tmp" && rm -f "$tmp" "$tmp.sig"
```

If prompts return unexpectedly, first confirm the key is listed in `ssh-add -L` and the shell is using the expected `SSH_AUTH_SOCK`.
