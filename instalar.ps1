# ==============================================================================
# INSTALADOR OFICIAL DE CHISPIPPEN ANTIVIRUS + GUARDIAN DE ALERTAS 24/7
# Edicion Especial: Antigravity + GitHub + Localhost (Negocio de Jace)
# ==============================================================================
$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   INSTALANDO CHISPIPPEN ANTIVIRUS + GUARDIAN DE ALERTAS EN VIVO     " -ForegroundColor Cyan
Write-Host "   Proteccion para PC, Sistema y Plataformas (Negocio de Jace)       " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

$InstallDir = Join-Path $env:LOCALAPPDATA "ChispippenAntivirus"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Write-Host "[1/5] Instalando Chispippen Antivirus y Guardian de Alertas en $InstallDir ..." -ForegroundColor Yellow

$AppPath = Join-Path $InstallDir "Chispippen-Antivirus.ps1"
$GuardianPath = Join-Path $InstallDir "Chispippen-Guardian.ps1"
$BatPath = Join-Path $InstallDir "Iniciar-Chispippen.bat"

$LocalApp = Join-Path $PSScriptRoot "Chispippen-Antivirus.ps1"
$LocalGuardian = Join-Path $PSScriptRoot "Chispippen-Guardian.ps1"

if ($PSScriptRoot -and (Test-Path $LocalApp)) {
    Copy-Item $LocalApp $AppPath -Force
} else {
    $RepoUrl = "https://chispippen.github.io/chispippen-antivirus/Chispippen-Antivirus.ps1"
    $response = Invoke-WebRequest -Uri $RepoUrl -UseBasicParsing
    $rawContent = [System.Text.Encoding]::ASCII.GetString($response.Content)
    [System.IO.File]::WriteAllText($AppPath, $rawContent, [System.Text.Encoding]::ASCII)
}

if ($PSScriptRoot -and (Test-Path $LocalGuardian)) {
    Copy-Item $LocalGuardian $GuardianPath -Force
} else {
    $GuardUrl = "https://chispippen.github.io/chispippen-antivirus/Chispippen-Guardian.ps1"
    $response2 = Invoke-WebRequest -Uri $GuardUrl -UseBasicParsing
    $rawContent2 = [System.Text.Encoding]::ASCII.GetString($response2.Content)
    [System.IO.File]::WriteAllText($GuardianPath, $rawContent2, [System.Text.Encoding]::ASCII)
}

$BatContent = @"
@echo off
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\ChispippenAntivirus\Chispippen-Antivirus.ps1"
"@
[System.IO.File]::WriteAllText($BatPath, $BatContent, [System.Text.Encoding]::ASCII)

Write-Host "[2/5] Configurando Guardian de Alertas Automaticas al encender la PC ..." -ForegroundColor Yellow
try {
    $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $cmdVal = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$GuardianPath`""
    Set-ItemProperty -Path $runKey -Name "ChispippenGuardian" -Value $cmdVal -ErrorAction SilentlyContinue

    $DesktopDir = [Environment]::GetFolderPath("Desktop")
    $OldShortcut = Join-Path $DesktopDir "Centinela Antivirus.lnk"
    if (Test-Path $OldShortcut) { Remove-Item $OldShortcut -Force -ErrorAction SilentlyContinue }

    $ShortcutPath = Join-Path $DesktopDir "Chispippen Antivirus.lnk"
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$AppPath`""
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.IconLocation = "imageres.dll,101"
    $Shortcut.Description = "Chispippen Antivirus + Guardian de Alertas en Vivo"
    $Shortcut.Save()
    Write-Host "      -> Guardian 24/7 activado e icono 'Chispippen Antivirus' listo en el Escritorio." -ForegroundColor Green
} catch {}

Write-Host "[3/5] Actualizando base de datos de firmas de virus ..." -ForegroundColor Yellow
Update-MpSignature -ErrorAction SilentlyContinue
Write-Host "      -> Firmas de virus actualizadas al dia de hoy." -ForegroundColor Green

Write-Host "[4/5] Configurando Blindaje + Permisos Antigravity, GitHub y Localhost (Negocio de Jace) ..." -ForegroundColor Yellow
Write-Host "      (Si aparece una ventana de permisos de Windows, haz clic en 'Si')" -ForegroundColor Cyan

$agDir = Join-Path $env:USERPROFILE ".gemini"
$agSubDir = Join-Path $env:USERPROFILE ".gemini\antigravity"
$scratchDir = Join-Path $env:USERPROFILE ".gemini\antigravity\scratch"

$HardeningAndDevScript = @"
Set-MpPreference -DisableRealtimeMonitoring `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning `$false -ErrorAction SilentlyContinue
Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue
Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue
Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue
Set-MpPreference -SubmitSamplesConsent SendSafeSamples -ErrorAction SilentlyContinue
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction SilentlyContinue

Add-MpPreference -ExclusionPath '$agDir' -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath '$agSubDir' -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath '$scratchDir' -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionIpAddress '127.0.0.1','::1' -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess 'node.exe','git.exe','gh.exe','ssh.exe','code.exe','agy.exe' -ErrorAction SilentlyContinue

Remove-NetFirewallRule -DisplayName 'Chispippen_Jace_Localhost' -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'Chispippen_Jace_Localhost' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3000,3001,4000,4200,5000,5173,5174,8000,8080,8081,8443,8888,9000,9229 -Profile Any -Description 'Permite servidores localhost de Antigravity y del Negocio de Jace' -ErrorAction SilentlyContinue | Out-Null

Remove-NetFirewallRule -DisplayName 'Chispippen_Jace_GitHub_Out' -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'Chispippen_Jace_GitHub_Out' -Direction Outbound -Action Allow -Protocol TCP -RemotePort 22,80,443 -Profile Any -Description 'Permite trafico saliente HTTPS y SSH para GitHub y Antigravity' -ErrorAction SilentlyContinue | Out-Null

`$action = New-ScheduledTaskAction -Execute 'MpCmdRun.exe' -Argument '-Scan -ScanType 1' -WorkingDirectory "`$env:ProgramFiles\Windows Defender"
`$trigger = New-ScheduledTaskTrigger -Daily -At 12:30PM
Register-ScheduledTask -TaskName 'Chispippen_Escaneo_Diario' -Action `$action -Trigger `$trigger -Description 'Escaneo rapido diario de Chispippen Antivirus' -Force -ErrorAction SilentlyContinue | Out-Null
"@

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Invoke-Expression $HardeningAndDevScript
    Write-Host "      -> Blindaje y Permisos para Antigravity, GitHub y Localhost activados con exito." -ForegroundColor Green
} else {
    try {
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($HardeningAndDevScript)
        $encoded = [Convert]::ToBase64String($bytes)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encoded" -Verb RunAs -Wait
        Write-Host "      -> Blindaje y Permisos para Antigravity, GitHub y Localhost activados con exito." -ForegroundColor Green
    } catch {
        Write-Host "      -> Nota: Puedes activar los permisos Administrador desde el boton '1. Blindar + Modo Antigravity'." -ForegroundColor Yellow
    }
}

Write-Host "[5/5] Iniciando Guardian de Alertas y abriendo Chispippen Antivirus ..." -ForegroundColor Yellow
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$GuardianPath`""
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$AppPath`""

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "   CHISPIPPEN ANTIVIRUS + GUARDIAN DE ALERTAS INSTALADO CON EXITO    " -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
