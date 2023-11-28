# Windows Terminal setup

To setup Terminal, you first need to have set up Ubuntu and have cloned this repo.

Then simply use the following:

```ps
$LINUX_CONFIG_PATH="\\wsl.localhost\Ubuntu\home\bosco\repos\Linux-config\Windows"

<!-- PowerShell profile -->
cd C:\Users\bosco\Documents\PowerShell\
mv .\Microsoft.PowerShell_profile.ps1 .\Microsoft.PowerShell_profile.ps1.bak && New-Item -ItemType SymbolicLink -Path ".\Microsoft.PowerShell_profile.ps1" -Target "$LINUX_CONFIG_PATH\Microsoft.PowerShell_profile.ps1"

<!-- Terminal settings -->
cd C:\Users\bosco\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState
mv .\settings.json .\settings.json.bak && New-Item -ItemType SymbolicLink -Path ".\settings.json" -Target "$LINUX_CONFIG_PATH\settings.json"
```