# VS Code / Cursor settings

For VS Code the settings sync should work well enough. For Cursor, the settings sync is not available and thus more manual management is needed.

## Semi-automated setup

Use the built-in Profile Manager to export files. However, it may not work perfectly (as of 2025-04 the extensions importer is broken).

## Windows

Powershell:

```powershell
rm "C:\Users\bosco\AppData\Roaming\Cursor\User\settings.json" "C:\Users\bosco\AppData\Roaming\Cursor\User\keybindings.json"

New-Item -Path "C:\Users\bosco\AppData\Roaming\Cursor\User\settings.json" -ItemType SymbolicLink -Value "\\wsl.localhost\Ubuntu\home\bosco\repos\Linux-config\vscode\settings.json"

New-Item -Path "C:\Users\bosco\AppData\Roaming\Cursor\User\keybindings.json" -ItemType SymbolicLink -Value "\\wsl.localhost\Ubuntu\home\bosco\repos\Linux-config\vscode\keybindings.json"
```

## Linux

```sh
rm ~/.config/Cursor/User/settings.json ~/.config/Cursor/User/keybindings.json
ln -s ~/repos/Linux-config/vscode/settings.json ~/.config/Cursor/User/settings.json
ln -s ~/repos/Linux-config/vscode/keybindings.json ~/.config/Cursor/User/keybindings.json
```

## Extensions

In source machine:

```sh
cursor --list-extensions > ./vscode/extensions.list
```

In target machine:

```sh
cat ./vscode/extensions.list | xargs -n 1 cursor --install-extension
```
