function Get-IsElevated {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
    { Write-Output $true }      
    else
    { Write-Output $false }   
}

function Install-IfNotInstalled {
    param (
        [string]$package,
        [string]$scope
    )

    if ("$(winget list --id $package)".Contains("--")) { 
        Write-Host "$package is already installed!" -ForegroundColor Green
    }
    else {
        Write-Host "Attempting to install: $package..." -ForegroundColor Yellow
        winget install $package -i --scope $scope
    }
}

if (-not(Get-IsElevated)) { 
    throw "Please run this script as an administrator" 
}

if (-not $(Get-Command winget)) {
    Start-Process "https://github.com/microsoft/winget-cli/releases"
    return
}

Install-IfNotInstalled Microsoft.VisualStudioCode -scope machine
Install-IfNotInstalled Microsoft.WindowsTerminal  -scope machine
Install-IfNotInstalled Microsoft.Teams  -scope machine
Install-IfNotInstalled Microsoft.Office -scope machine
Install-IfNotInstalled Microsoft.OneDrive -scope machine
Install-IfNotInstalled Microsoft.PowerShell -scope machine
Install-IfNotInstalled Microsoft.dotnet -scope machine
Install-IfNotInstalled Microsoft.Edge -scope machine
Install-IfNotInstalled Microsoft.EdgeWebView2Runtime -scope machine
# We shall not install Visual Studio. Since the user may not buy enterprise license.
# winget install Microsoft.VisualStudio.2019.Enterprise
Install-IfNotInstalled Microsoft.AzureDataStudio -scope machine
Install-IfNotInstalled Tencent.WeChat -scope machine
Install-IfNotInstalled SoftDeluxe.FreeDownloadManager -scope machine
Install-IfNotInstalled VideoLAN.VLC -scope machine
Install-IfNotInstalled OBSProject.OBSStudio -scope machine
Install-IfNotInstalled Git.git -scope machine
Install-IfNotInstalled OpenJS.NodeJS -scope machine
Install-IfNotInstalled Postman.Postman -scope machine
Install-IfNotInstalled 7zip.7zip -scope machine

Write-Host "Setting execution policy to remotesigned..." -ForegroundColor Yellow
Set-ExecutionPolicy remotesigned

Write-Host "Setting up .NET environment variables..." -ForegroundColor Yellow
$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:DOTNET_PRINT_TELEMETRY_MESSAGE = 'false'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

Write-Host "Copying back SSH keys..." -ForegroundColor Yellow
$HOME | Where-Object { $_.Name -like "OneDrive*" }
$OneDrivePath = $(Get-ChildItem -Path $HOME | Where-Object { $_.Name -like "OneDrive*" } | Sort-Object Name -Descending | Select-Object -First 1).Name
Copy-Item -Path "$HOME\$OneDrivePath\Storage\SSH\*" -Destination "$HOME\.ssh\"

Write-Host "Copying back windows terminal configuration file..." -ForegroundColor Yellow
$wtConfigPath = "C:\Users\xuef.FAREAST\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Copy-Item -Path "$HOME\$OneDrivePath\Storage\WT\settings.json" -Destination $wtConfigPath

Write-Host "Configuring windows terminal context menu..." -ForegroundColor Yellow
git clone git@github.com:lextm/windowsterminal-shell.git "$HOME\temp"
pwsh -command "$HOME\temp\install.ps1 mini"
Remove-Item $HOME\temp -Force -Recurse -Confirm:$false

Write-Host "Setting up .NET build environment..." -ForegroundColor Yellow
git clone git@github.com:AiursoftWeb/Infrastructures.git "$HOME/source/repos/AiursoftWeb"
git clone git@github.com:AiursoftWeb/AiurVersionControl.git "$HOME/source/repos/AiursoftWeb"
dotnet test "$HOME\source\repos\AiursoftWeb\Aiursoft.Infrastructures.sln"

Write-Host "Enabling desktop icons..." -ForegroundColor Yellow
cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu /v {20D04FE0-3AEA-1069-A2D8-08002B30309D} /t REG_DWORD /d 0 /f"
cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel /v {20D04FE0-3AEA-1069-A2D8-08002B30309D} /t REG_DWORD /d 0 /f"
cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu /v {59031a47-3f72-44a7-89c5-5595fe6b30ee} /t REG_DWORD /d 0 /f"
cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel /v {59031a47-3f72-44a7-89c5-5595fe6b30ee} /t REG_DWORD /d 0 /f"
cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu /v {645FF040-5081-101B-9F08-00AA002F954E} /t REG_DWORD /d 0 /f"
cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel /v {645FF040-5081-101B-9F08-00AA002F954E} /t REG_DWORD /d 0 /f"
cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu /v {F02C1A0D-BE21-4350-88B0-7367FC96EF3C} /t REG_DWORD /d 0 /f"
cmd.exe /c "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel /v {F02C1A0D-BE21-4350-88B0-7367FC96EF3C} /t REG_DWORD /d 0 /f"

# Clean
Write-Host "Cleaning desktop..." -ForegroundColor Yellow
Remove-Item $HOME\Desktop\* -Force -Recurse -Confirm:$false
Remove-Item "C:\Users\Public\Desktop\*" -Force -Recurse -Confirm:$false
Stop-Process -Name explorer -Force

Write-Host "Attempting to download spotify installer..." -ForegroundColor Yellow
$source = 'https://download.scdn.co/SpotifySetup.exe'
Invoke-WebRequest -Uri $source -OutFile "$HOME\Desktop\spotify.exe"

# Finally, upgrade all.
Write-Host "Checking for final upgrades..." -ForegroundColor Yellow
winget upgrade --all

# Consider to reboot.
shutdown -r -t 60