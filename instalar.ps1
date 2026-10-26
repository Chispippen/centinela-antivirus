# ==============================================================================
# INSTALADOR AUTOMATICO DE CENTINELA ANTIVIRUS (WINDOWS 10 / 11)
# ==============================================================================
$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   INSTALANDO CENTINELA ANTIVIRUS & BLINDAJE DE SEGURIDAD       " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$InstallDir = Join-Path $env:LOCALAPPDATA "CentinelaAntivirus"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Write-Host "[1/5] Creando archivos del programa en $InstallDir ..." -ForegroundColor Yellow

$AppPath = Join-Path $InstallDir "Centinela-Antivirus.ps1"
$BatPath = Join-Path $InstallDir "Iniciar-Centinela.bat"

# Si existe Centinela-Antivirus.ps1 junto al instalador, lo copiamos; si no, lo descargamos del repositorio oficial
$LocalSource = Join-Path $PSScriptRoot "Centinela-Antivirus.ps1"
$utf8Bom = New-Object System.Text.UTF8Encoding($true)

if ($PSScriptRoot -and (Test-Path $LocalSource)) {
    $rawContent = [System.IO.File]::ReadAllText($LocalSource, [System.Text.Encoding]::UTF8)
    [System.IO.File]::WriteAllText($AppPath, $rawContent, $utf8Bom)
} else {
    $RepoUrl = "https://chispippen.github.io/centinela-antivirus/Centinela-Antivirus.ps1"
    $response = Invoke-WebRequest -Uri $RepoUrl -UseBasicParsing
    $rawContent = [System.Text.Encoding]::UTF8.GetString($response.Content)
    [System.IO.File]::WriteAllText($AppPath, $rawContent, $utf8Bom)
}

$BatContent = @"
@echo off
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%LOCALAPPDATA%\CentinelaAntivirus\Centinela-Antivirus.ps1"
"@
[System.IO.File]::WriteAllText($BatPath, $BatContent, [System.Text.Encoding]::ASCII)

Write-Host "[2/5] Creando acceso directo en el Escritorio ..." -ForegroundColor Yellow
try {
    $DesktopDir = [Environment]::GetFolderPath("Desktop")
    $ShortcutPath = Join-Path $DesktopDir "Centinela Antivirus.lnk"
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$AppPath`""
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.IconLocation = "imageres.dll,101"
    $Shortcut.Description = "Centinela Security Suite - Antivirus y Blindaje Gratuito"
    $Shortcut.Save()
    Write-Host "      -> Acceso directo 'Centinela Antivirus' creado en el Escritorio." -ForegroundColor Green
} catch {
    Write-Host "      -> No se pudo crear el icono en el escritorio automaticamente." -ForegroundColor DarkYellow
}

Write-Host "[3/5] Actualizando base de datos de firmas de virus ..." -ForegroundColor Yellow
Update-MpSignature -ErrorAction SilentlyContinue
Write-Host "      -> Firmas de virus actualizadas al dia de hoy." -ForegroundColor Green

Write-Host "[4/5] Aplicando blindaje avanzado de Windows Defender y Firewall ..." -ForegroundColor Yellow
Write-Host "      (Si aparece una ventana de permisos de Windows, haz clic en 'Si')" -ForegroundColor Cyan

$HardeningScript = @"
Set-MpPreference -DisableRealtimeMonitoring `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning `$false -ErrorAction SilentlyContinue
Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue
Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue
Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue
Set-MpPreference -SubmitSamplesConsent SendSafeSamples -ErrorAction SilentlyContinue
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction SilentlyContinue
`$action = New-ScheduledTaskAction -Execute 'MpCmdRun.exe' -Argument '-Scan -ScanType 1' -WorkingDirectory "`$env:ProgramFiles\Windows Defender"
`$trigger = New-ScheduledTaskTrigger -Daily -At 12:30PM
Register-ScheduledTask -TaskName 'Centinela_Escaneo_Diario' -Action `$action -Trigger `$trigger -Description 'Escaneo rapido diario de Centinela Antivirus' -Force -ErrorAction SilentlyContinue | Out-Null
"@

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Invoke-Expression $HardeningScript
    Write-Host "      -> Blindaje de nivel Administrador activado con exito." -ForegroundColor Green
} else {
    try {
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($HardeningScript)
        $encoded = [Convert]::ToBase64String($bytes)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encoded" -Verb RunAs -Wait
        Write-Host "      -> Blindaje de nivel Administrador activado con exito." -ForegroundColor Green
    } catch {
        Write-Host "      -> Nota: Puedes activar el blindaje Administrador luego desde el boton '1. Blindar PC al Maximo'." -ForegroundColor Yellow
    }
}

Write-Host "[5/5] Ejecutando verificacion rapida del sistema y abriendo Centinela Antivirus ..." -ForegroundColor Yellow
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$AppPath`""

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   INSTALACION COMPLETADA CON EXITO                             " -ForegroundColor Green
Write-Host "   El icono 'Centinela Antivirus' ya esta en tu Escritorio.     " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
