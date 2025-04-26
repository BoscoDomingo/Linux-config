# Access this file by running `code $PROFILE`, refresh with `& $PROFILE`
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/niceDark.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/devious-diamonds.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/iterm2.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/blueish.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/blue-owl.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/craver.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/easy-term.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/jv_sitecorian.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/powerlevel10k_rainbow.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/slimfat.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/ys.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/night-owl.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/gmay.omp.json" | Invoke-Expression

# @antfu/ni support
Remove-Item Alias:ni -Force -ErrorAction Ignore

function cdhome {
    cd $USERPROFILE
}
function cddl {
    cd C:\Users\Bosco\Downloads\
}

function startDockerIfNeeded {
    $processes = Get-Process "*docker desktop*"
    if ($processes.Count -gt 0)
    {
        Write-Host "Docker is already running"
    }
    else
    {
        Write-Host "Starting Docker"
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    }
}

function killDocker {
    $processes = Get-Process "*docker desktop*"
    if ($processes.Count -gt 0)
    {
        $processes[0].Kill()
        $processes[0].WaitForExit()
    }
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58
