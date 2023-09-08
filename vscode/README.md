# VS Code / Cursor settings

**For VS Code the built-in settings sync should work well enough**.

For Cursor, the settings sync is not available and thus more manual management is needed.

## Automated setup

Probably the best way to go about it is to ensure VS Code is correctly set up and synced in the source machine, install it and download the settings on the target machine, and then import the VS Code setup to Cursor.

## Semi-automated setup

Use the built-in Profile Manager to export files. However, it may not work perfectly (as of 2025-04 the extensions importer is broken).

## Windows

Powershell:

```powershell
# Cursor
$LinuxConfigPath = "\\wsl.localhost\Ubuntu\home\bosco\repos\Linux-config"
mv "C:\Users\bosco\AppData\Roaming\Cursor\User\settings.json" "C:\Users\bosco\AppData\Roaming\Cursor\User\settings.backup.json"
mv "C:\Users\bosco\AppData\Roaming\Cursor\User\keybindings.json" "C:\Users\bosco\AppData\Roaming\Cursor\User\keybindings.backup.json"
mv "C:\Users\bosco\.cursor\extensions\extensions.json" "C:\Users\bosco\.cursor\extensions\extensions.backup.json"
New-Item -Path "C:\Users\bosco\AppData\Roaming\Cursor\User\settings.json" -ItemType SymbolicLink -Value "$LinuxConfigPath\vscode\settings.json"
New-Item -Path "C:\Users\bosco\AppData\Roaming\Cursor\User\keybindings.json" -ItemType SymbolicLink -Value "$LinuxConfigPath\vscode\keybindings.json"
New-Item -Path "C:\Users\bosco\.cursor\extensions\extensions.json" -ItemType SymbolicLink -Value "$LinuxConfigPath\vscode\extensions-cursor.json"

# VS Code
$LinuxConfigPath = "\\wsl.localhost\Ubuntu\home\bosco\repos\Linux-config"
mv "C:\Users\bosco\AppData\Roaming\Code\User\settings.json" "C:\Users\bosco\AppData\Roaming\Code\User\settings.backup.json"
mv "C:\Users\bosco\AppData\Roaming\Code\User\keybindings.json" "C:\Users\bosco\AppData\Roaming\Code\User\keybindings.backup.json"
New-Item -Path "C:\Users\bosco\AppData\Roaming\Code\User\settings.json" -ItemType SymbolicLink -Value "$LinuxConfigPath\vscode\settings.json"
New-Item -Path "C:\Users\bosco\AppData\Roaming\Code\User\keybindings.json" -ItemType SymbolicLink -Value "$LinuxConfigPath\vscode\keybindings.json"
```

## Linux

```sh
# Cursor
$LinuxConfigPath = "~/repos/Linux-config"
mv ~/.config/Cursor/User/settings.json ~/.config/Cursor/User/settings.backup.json
mv ~/.config/Cursor/User/keybindings.json ~/.config/Cursor/User/keybindings.backup.json
ln -s $LinuxConfigPath/vscode/settings.json ~/.config/Cursor/User/settings.json
ln -s $LinuxConfigPath/vscode/keybindings.json ~/.config/Cursor/User/keybindings.json
ln -s $LinuxConfigPath/vscode/extensions-cursor-linux.json ~/.cursor-server/extensions/extensions.json

# VS Code
LinuxConfigPath="~/repos/Linux-config"
mv ~/.config/Code/User/settings.json ~/.config/Code/User/settings.backup.json
mv ~/.config/Code/User/keybindings.json ~/.config/Code/User/keybindings.backup.json
ln -s $LinuxConfigPath/vscode/settings.json ~/.config/Code/User/settings.json
ln -s $LinuxConfigPath/vscode/keybindings.json ~/.config/Code/User/keybindings.json
```

## Exporting and importing extensions

This exports the raw list, with no mention of which are enabled. It's a more crude approach than using the files mentioned above.

In source machine:

```sh
cursor --list-extensions > ./vscode/extensions.list
```

In target machine:

```sh
cat ./vscode/extensions.list | xargs -n 1 cursor --install-extension
```
