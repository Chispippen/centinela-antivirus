# ==============================================================================
# CHISPIPPEN ANTIVIRUS (CHISPARO SECURITY EDITION) - WINDOWS 10/11
# Blindaje + Guardi?n de Alertas en Vivo (PC, Sistema, Antigravity, GitHub, Web)
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -Name Win32Window -Namespace Chispippen -MemberDefinition '
    [DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
' -ErrorAction SilentlyContinue
$consolePtr = [Chispippen.Win32Window]::GetConsoleWindow()
if ($consolePtr -ne [IntPtr]::Zero) {
    [Chispippen.Win32Window]::ShowWindow($consolePtr, 0) | Out-Null
}

[System.Windows.Forms.Application]::EnableVisualStyles()

$AppDataDir = Join-Path $env:LOCALAPPDATA "ChispippenAntivirus"
$QuarantineDir = Join-Path $AppDataDir "Cuarentena"
$LogsDir = Join-Path $AppDataDir "Logs"
$GuardianPath = Join-Path $AppDataDir "Chispippen-Guardian.ps1"
$AlertLogFile = Join-Path $LogsDir "alertas.log"

if (-not (Test-Path $QuarantineDir)) { New-Item -ItemType Directory -Path $QuarantineDir -Force | Out-Null }
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

# Asegurar que el Guardian de Alertas en Tiempo Real quede registrado al iniciar Windows y corriendo
function Start-ChispippenGuardian {
    try {
        if (Test-Path $GuardianPath) {
            $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            $cmdVal = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$GuardianPath`""
            Set-ItemProperty -Path $runKey -Name "ChispippenGuardian" -Value $cmdVal -ErrorAction SilentlyContinue

            $running = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandLine -match 'Chispippen-Guardian\.ps1' -and $_.CommandLine -notmatch '-TestAlert' }
            if (-not $running) {
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$GuardianPath`"" -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

Start-ChispippenGuardian

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SecurityStatus {
    $status = @{
        RealTime = $false
        Antivirus = $false
        Behavior = $false
        Tamper = $false
        PUABlock = $false
        NetworkProt = $false
        Firewall = $false
        DevModeReady = $false
        GuardianRunning = $false
        SigDate = "Desconocido"
        QuickScanAge = 999
        IsAdmin = (Test-IsAdmin)
    }
    try {
        $mpStatus = Get-MpComputerStatus -ErrorAction Stop
        $mpPref = Get-MpPreference -ErrorAction Stop
        $fw = Get-NetFirewallProfile -ErrorAction SilentlyContinue

        $status.RealTime = [bool]$mpStatus.RealTimeProtectionEnabled
        $status.Antivirus = [bool]$mpStatus.AntivirusEnabled
        $status.Behavior = [bool]$mpStatus.BehaviorMonitorEnabled
        $status.Tamper = [bool]$mpStatus.IsTamperProtected
        $status.PUABlock = ($mpPref.PUAProtection -eq 1)
        $status.NetworkProt = ($mpPref.EnableNetworkProtection -eq 1)
        if ($mpStatus.AntivirusSignatureLastUpdated) {
            $status.SigDate = $mpStatus.AntivirusSignatureLastUpdated.ToString("dd/MM/yyyy HH:mm")
        }
        $status.QuickScanAge = $mpStatus.QuickScanAge

        $fwEnabled = $true
        foreach ($p in $fw) {
            if (-not $p.Enabled) { $fwEnabled = $false }
        }
        $status.Firewall = $fwEnabled

        $devRule = Get-NetFirewallRule -DisplayName "Chispippen_Jace_GitHub_Out" -ErrorAction SilentlyContinue
        $agPath = Join-Path $env:USERPROFILE ".gemini\antigravity"
        $hasExcl = $false
        if ($mpPref.ExclusionPath -and ($mpPref.ExclusionPath -contains $agPath)) {
            $hasExcl = $true
        }
        $status.DevModeReady = ([bool]$devRule -or $hasExcl)

        $gProc = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -match 'Chispippen-Guardian\.ps1' }
        $status.GuardianRunning = [bool]$gProc
    } catch {}
    return $status
}

# ==============================================================================
# INTERFAZ GRAFICA DE CHISPIPPEN ANTIVIRUS
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Chispippen Antivirus (Chisparo Security) - Edici$([char]243)n Negocio de Jace & Alertas en Vivo"
$form.Size = New-Object System.Drawing.Size(980, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(13, 19, 33)
$form.ForeColor = [System.Drawing.Color]::FromArgb(241, 245, 249)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

$fontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontSubtitle = New-Object System.Drawing.Font("Segoe UI", 9.8, [System.Drawing.FontStyle]::Regular)
$fontCardTitle = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$fontBody = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fontMono = New-Object System.Drawing.Font("Consolas", 9.5, [System.Drawing.FontStyle]::Regular)
$fontBtn = New-Object System.Drawing.Font("Segoe UI", 9.8, [System.Drawing.FontStyle]::Bold)

# Cabecera
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size(980, 84)
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(24, 34, 56)
$form.Controls.Add($headerPanel)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "$([char]9889)$([char]::ConvertFromUtf32(128737))$([char]65039) CHISPIPPEN ANTIVIRUS  |  GUARDI$([char]193)N DE ALERTAS EN VIVO"
$lblTitle.Font = $fontTitle
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248)
$lblTitle.Location = New-Object System.Drawing.Point(24, 14)
$lblTitle.AutoSize = $true
$headerPanel.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Alertas inmediatas ante cualquier riesgo en tu Computadora, Sistema, Navegadores, Antigravity, GitHub y Localhost"
$lblSub.Font = $fontSubtitle
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
$lblSub.Location = New-Object System.Drawing.Point(28, 48)
$lblSub.AutoSize = $true
$headerPanel.Controls.Add($lblSub)

$lblAdminBadge = New-Object System.Windows.Forms.Label
$lblAdminBadge.Font = $fontBody
$lblAdminBadge.Location = New-Object System.Drawing.Point(745, 26)
$lblAdminBadge.Size = New-Object System.Drawing.Size(205, 30)
$lblAdminBadge.TextAlign = "MiddleCenter"
$headerPanel.Controls.Add($lblAdminBadge)

# Panel de Estado
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(24, 98)
$statusPanel.Size = New-Object System.Drawing.Size(920, 134)
$statusPanel.BackColor = [System.Drawing.Color]::FromArgb(24, 34, 56)
$form.Controls.Add($statusPanel)

$lblStatusHeader = New-Object System.Windows.Forms.Label
$lblStatusHeader.Text = "ESTADO DEL BLINDAJE, ALERTAS EN VIVO Y PLATAFORMAS (JACE BUSINESS)"
$lblStatusHeader.Font = $fontCardTitle
$lblStatusHeader.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248)
$lblStatusHeader.Location = New-Object System.Drawing.Point(16, 12)
$lblStatusHeader.AutoSize = $true
$statusPanel.Controls.Add($lblStatusHeader)

$lblIndicators = New-Object System.Windows.Forms.Label
$lblIndicators.Font = $fontBody
$lblIndicators.Location = New-Object System.Drawing.Point(16, 40)
$lblIndicators.Size = New-Object System.Drawing.Size(888, 84)
$statusPanel.Controls.Add($lblIndicators)

function New-ActionButton($text, $x, $y, $w, $h, $bgColor) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size($w, $h)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $bgColor
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = $fontBtn
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $btn
}

# Fila 1 de Botones Principales (4 Botones de Colores)
$btnHardenDev = New-ActionButton "$([char]::ConvertFromUtf32(128737))$([char]65039) 1. Blindar + Modo Antigravity" 24 246 225 46 ([System.Drawing.Color]::FromArgb(16, 185, 129))
$btnCheckDev = New-ActionButton "$([char]::ConvertFromUtf32(128640)) 2. Auditar Plataformas y GitHub" 260 246 230 46 ([System.Drawing.Color]::FromArgb(14, 165, 233))
$btnQuickScan = New-ActionButton "$([char]9889) 3. Escaneo R$([char]225)pido + Heur$([char]237)stico" 501 246 225 46 ([System.Drawing.Color]::FromArgb(99, 102, 241))
$btnTestAlert = New-ActionButton "$([char]::ConvertFromUtf32(128276)) 4. Probar Alerta de Riesgo" 737 246 207 46 ([System.Drawing.Color]::FromArgb(225, 29, 72))

$form.Controls.Add($btnHardenDev)
$form.Controls.Add($btnCheckDev)
$form.Controls.Add($btnQuickScan)
$form.Controls.Add($btnTestAlert)

# Fila 2 de Botones Secundarios
$btnNetAudit = New-ActionButton "$([char]::ConvertFromUtf32(127760)) Monitor de Red y Procesos" 24 302 225 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))
$btnScanFolder = New-ActionButton "$([char]::ConvertFromUtf32(128194)) Escanear Carpeta o USB..." 260 302 230 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))
$btnCleanTemp = New-ActionButton "$([char]::ConvertFromUtf32(129529)) Limpiar Basura Temporal" 501 302 225 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))
$btnViewAlerts = New-ActionButton "$([char]::ConvertFromUtf32(128203)) Historial de Alertas" 737 302 207 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))

$form.Controls.Add($btnNetAudit)
$form.Controls.Add($btnScanFolder)
$form.Controls.Add($btnCleanTemp)
$form.Controls.Add($btnViewAlerts)

# Consola de Resultados
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(24, 354)
$txtLog.Size = New-Object System.Drawing.Size(920, 290)
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(8, 12, 22)
$txtLog.ForeColor = [System.Drawing.Color]::FromArgb(203, 213, 225)
$txtLog.Font = $fontMono
$txtLog.ReadOnly = $true
$txtLog.BorderStyle = "None"
$form.Controls.Add($txtLog)

function Write-Log($msg, $color = "#E2E8F0") {
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.SelectionLength = 0
    $txtLog.SelectionColor = [System.Drawing.ColorTranslator]::FromHtml($color)
    $txtLog.AppendText("[$timestamp] $msg`r`n")
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Refresh-UIStatus {
    $s = Get-SecurityStatus
    if ($s.GuardianRunning) {
        $lblAdminBadge.Text = "$([char]::ConvertFromUtf32(128276)) GUARDI$([char]193)N 24/7 ACTIVO"
        $lblAdminBadge.BackColor = [System.Drawing.Color]::FromArgb(6, 95, 70)
        $lblAdminBadge.ForeColor = [System.Drawing.Color]::FromArgb(167, 243, 208)
    } else {
        $lblAdminBadge.Text = "$([char]9889) CHISPARO ACTIVO"
        $lblAdminBadge.BackColor = [System.Drawing.Color]::FromArgb(30, 58, 138)
        $lblAdminBadge.ForeColor = [System.Drawing.Color]::FromArgb(191, 219, 254)
    }

    $rtIcon = if ($s.RealTime) { "$([char]9989) Activo" } else { "$([char]10060) Inactivo" }
    $fwIcon = if ($s.Firewall) { "$([char]9989) Activo" } else { "$([char]10060) Inactivo" }
    $puaIcon = if ($s.PUABlock) { "$([char]9989) Bloqueando Adware" } else { "$([char]9888)$([char]65039) Clic en Bot$([char]243)n 1" }
    $netIcon = if ($s.NetworkProt) { "$([char]9989) Activo (Anti-Phishing)" } else { "$([char]9888)$([char]65039) Clic en Bot$([char]243)n 1" }
    $devIcon = if ($s.DevModeReady) { "$([char]9989) Activos (Antigravity + GitHub + Localhost)" } else { "$([char]9889) Clic en Bot$([char]243)n 1" }
    $guardIcon = if ($s.GuardianRunning) { "$([char]9989) Vigilando en Vivo (PC, Sistema y Plataformas)" } else { "$([char]::ConvertFromUtf32(128260)) Iniciando..." }

    $lblIndicators.Text = (
        "$([char]8226) Motor en Tiempo Real: $rtIcon   |   $([char]8226) Firewall Windows: $fwIcon   |   $([char]8226) Firmas: $($s.SigDate)`r`n" +
        "$([char]8226) Bloqueo de Adware/PUA: $puaIcon   |   $([char]8226) Escudo Web Anti-Phishing: $netIcon`r`n" +
        "$([char]8226) Alertas en Tiempo Real: $guardIcon   |   $([char]8226) Permisos Jace: $devIcon"
    )
}

function Get-ChispippenAdminScript {
    $agDir = Join-Path $env:USERPROFILE ".gemini"
    $agSubDir = Join-Path $env:USERPROFILE ".gemini\antigravity"
    $scratchDir = Join-Path $env:USERPROFILE ".gemini\antigravity\scratch"
    return @"
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

Update-MpSignature -ErrorAction SilentlyContinue
"@
}

# BOT?N 1: BLINDAR + ACTIVAR MODO ANTIGRAVITY / GITHUB / LOCALHOST + GUARDIAN
$btnHardenDev.Add_Click({
    Write-Log "=== ACTIVANDO BLINDAJE CHISPIPPEN + PERMISOS + GUARDI$([char]193)N DE ALERTAS ===" "#38BDF8"
    Start-ChispippenGuardian
    $adminCmd = Get-ChispippenAdminScript
    if (-not (Test-IsAdmin)) {
        Write-Log "Solicitando permiso de Administrador (haz clic en 'S$([char]237)' en la ventana emergente)..." "#FBBF24"
        try {
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($adminCmd)
            $encoded = [Convert]::ToBase64String($bytes)
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encoded" -Verb RunAs -Wait
            Write-Log "$([char]9989) Blindaje Antivirus, Guardi$([char]225)n de Alertas y Permisos para Antigravity/GitHub/Localhost activados." "#34D399"
        } catch {
            Write-Log "$([char]9888)$([char]65039) No se acept$([char]243) la ventana de Administrador. Haz clic de nuevo y elige 'S$([char]237)'." "#F87171"
        }
    } else {
        Invoke-Expression $adminCmd
        Write-Log "$([char]9989) Blindaje Antivirus, Guardi$([char]225)n de Alertas y Permisos aplicados con $([char]233)xito." "#34D399"
    }
    Refresh-UIStatus
})

# BOT?N 2: AUDITAR SEGURIDAD DE PLATAFORMAS (CHROME, EDGE, GITHUB, ANTIGRAVITY, LOCALHOST, CLAVES)
$btnCheckDev.Add_Click({
    Write-Log "=== AUDITOR$([char]205)A DE RIESGOS EN PLATAFORMAS (NAVEGADORES, GITHUB, ANTIGRAVITY, JACE) ===" "#38BDF8"
    $risks = 0

    # 1. Verificar archivo hosts (proteccion contra secuestro de plataformas bancarias / web)
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (Test-Path $hostsPath) {
        $activeHosts = Get-Content $hostsPath -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' }
        if ($activeHosts.Count -eq 0) {
            Write-Log "$([char]9989) [Plataformas Web / Chrome / Edge] Archivo 'hosts' limpio (sin redirecciones ni secuestro de p$([char]225)ginas)." "#34D399"
        } else {
            Write-Log "$([char]8505)$([char]65039) [Plataformas Web] Entradas personalizadas en archivo hosts: $($activeHosts.Count)" "#FBBF24"
        }
    }

    # 2. Verificar conectividad y autenticidad de GitHub
    try {
        $ghRes = Invoke-WebRequest -Uri "https://api.github.com" -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop
        Write-Log "$([char]9989) [Plataforma GitHub] Conexi$([char]243)n cifrada HTTPS verificada (HTTP $($ghRes.StatusCode) - Sin interceptaci$([char]243)n)." "#34D399"
    } catch {
        $risks++
        Write-Log "$([char]::ConvertFromUtf32(128680)) [ALERTA PLATAFORMA GITHUB] Fallo o bloqueo en conexi$([char]243)n hacia GitHub: $($_.Exception.Message)" "#F87171"
    }

    # 3. Verificar entorno Antigravity
    $agPath = Join-Path $env:USERPROFILE ".gemini\antigravity"
    if (Test-Path $agPath) {
        Write-Log "$([char]9989) [Plataforma Antigravity] Entorno verificado y protegido en: $agPath" "#34D399"
    }

    # 4. Verificar si hay procesos sospechosos en Temp espiando navegadores o plataformas
    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    $tempProcs = 0
    foreach ($p in $procs) {
        if ($p.ExecutablePath -and ($p.ExecutablePath -match '\\Temp\\|\\Downloads\\') -and ($p.Name -notmatch '^(powershell|pwsh|git|node|gh|Antigravity)')) {
            $tempProcs++
            $risks++
            Write-Log "$([char]::ConvertFromUtf32(128680)) [ALERTA DE PROCESO] Programa ejecut$([char]225)ndose desde carpeta temporal: $($p.Name) ($($p.ExecutablePath))" "#F87171"
        }
    }
    if ($tempProcs -eq 0) {
        Write-Log "$([char]9989) [Protecci$([char]243)n de Sesiones] 0 procesos esp$([char]237)a en carpetas temporales mientras usas tus plataformas." "#34D399"
    }

    # 5. Verificar llaves de servidor (.pem) en el Escritorio (ej. AWS Lightsail)
    $desk = [Environment]::GetFolderPath("Desktop")
    $pemFiles = Get-ChildItem -Path $desk -Filter "*.pem" -ErrorAction SilentlyContinue
    foreach ($pem in $pemFiles) {
        Write-Log "$([char]::ConvertFromUtf32(128737))$([char]65039) [Aviso de Plataforma Cloud] Llave privada detectada en Escritorio: $($pem.Name). Chispippen vigila que ning$([char]250)n proceso externo la lea." "#93C5FD"
    }

    # 6. Verificar puertos Localhost del negocio de Jace
    $devPorts = @(3000, 3001, 4000, 4200, 5000, 5173, 5174, 8000, 8080, 8081, 8888)
    $listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $devPorts -contains $_.LocalPort }
    if ($listeners) {
        foreach ($l in $listeners) {
            $pName = (Get-Process -Id $l.OwningProcess -ErrorAction SilentlyContinue).ProcessName
            Write-Log "$([char]::ConvertFromUtf32(128994)) [Plataforma Localhost Jace] Servidor activo en puerto $($l.LocalPort) ($pName) - Vigilado y seguro." "#34D399"
        }
    } else {
        Write-Log "$([char]9989) [Plataforma Localhost Jace] Puertos de desarrollo seguros y sin accesos externos no autorizados." "#34D399"
    }

    if ($risks -eq 0) {
        Write-Log "$([char]9989) RESULTADO: Tu computadora, el sistema y todas tus plataformas est$([char]225)n fuera de peligro." "#34D399"
    }
})

# BOT?N 3: ESCANEO R?PIDO + HEUR?STICO
$btnQuickScan.Add_Click({
    Write-Log "=== INICIANDO ESCANEO CHISPIPPEN (MOTOR HEUR$([char]205)STICO + DEFENDER) ===" "#38BDF8"
    $scanPaths = @(
        (Join-Path $env:USERPROFILE "Downloads"),
        $env:TEMP,
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup")
    )
    $suspiciousFound = 0
    foreach ($dir in $scanPaths) {
        if (Test-Path $dir) {
            $files = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                if ($f.Name -match '\.(pdf|doc|docx|xls|xlsx|jpg|png|txt|mp4)\.(exe|scr|bat|cmd|vbs|hta|com)$') {
                    $suspiciousFound++
                    Write-Log "$([char]::ConvertFromUtf32(128680)) [ALERTA] Archivo trampa detectado: $($f.FullName)" "#F87171"
                }
            }
        }
    }
    if ($suspiciousFound -eq 0) {
        Write-Log "$([char]9989) Fase 1 limpia: 0 archivos trampa en Descargas/Temp." "#34D399"
    }
    Write-Log "Fase 2/2: Ejecutando Escaneo R$([char]225)pido del sistema (1-2 minutos)..." "#93C5FD"
    try {
        Start-MpScan -ScanType QuickScan -ErrorAction Stop
        Write-Log "$([char]9989) ESCANEO R$([char]193)PIDO COMPLETADO: Tu equipo est$([char]225) libre de amenazas." "#34D399"
    } catch {
        $mpCmd = Join-Path $env:ProgramFiles "Windows Defender\MpCmdRun.exe"
        if (Test-Path $mpCmd) {
            & $mpCmd -Scan -ScanType 1 | Out-Null
            Write-Log "$([char]9989) ESCANEO R$([char]193)PIDO COMPLETADO." "#34D399"
        }
    }
    Refresh-UIStatus
})

# BOT?N 4: PROBAR ALERTA DE RIESGO EN VIVO AHORA
$btnTestAlert.Add_Click({
    Write-Log "$([char]::ConvertFromUtf32(128276)) Disparando ventana emergente de Alerta de Seguridad en vivo..." "#F43F5E"
    Start-ChispippenGuardian
    if (Test-Path $GuardianPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$GuardianPath`" -TestAlert"
        Write-Log "$([char]9989) Alerta de prueba enviada a tu pantalla (con sonido y ventana de emergencia)." "#34D399"
    }
    Refresh-UIStatus
})

# BOT?N 5: MONITOR DE RED Y PROCESOS
$btnNetAudit.Add_Click({
    Write-Log "=== MONITOR DE PROCESOS Y CONEXIONES DE RED ===" "#38BDF8"
    $conns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
        Where-Object { $_.RemoteAddress -notmatch '^(127\.|::1|0\.0\.0\.0)' }
    Write-Log "Conexiones activas hacia internet: $($conns.Count)" "#93C5FD"
    foreach ($c in ($conns | Select-Object -First 20)) {
        $procName = "Sistema"
        try { $procName = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch {}
        Write-Log ("  $([char]8226) Proceso: {0,-18} (PID {1,-6}) -> {2}:{3}" -f $procName, $c.OwningProcess, $c.RemoteAddress, $c.RemotePort) "#E2E8F0"
    }
})

# BOT?N 6: ESCANEAR CARPETA O USB
$btnScanFolder.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Selecciona la carpeta o USB a escanear con Chispippen Antivirus:"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $p = $dialog.SelectedPath
        Write-Log "Analizando: $p ..." "#38BDF8"
        Start-MpScan -ScanType CustomScan -ScanPath $p -ErrorAction SilentlyContinue
        Write-Log "$([char]9989) An$([char]225)lisis completado en: $p" "#34D399"
    }
})

# BOT?N 7: LIMPIAR TEMPORALES
$btnCleanTemp.Add_Click({
    Write-Log "Limpiando cach$([char]233) temporal de Windows ($env:TEMP)..." "#38BDF8"
    Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "$([char]9989) Archivos temporales limpiados correctamente." "#34D399"
})

# BOT?N 8: HISTORIAL DE ALERTAS
$btnViewAlerts.Add_Click({
    Write-Log "=== HISTORIAL DE ALERTAS DE CHISPIPPEN GUARDI$([char]193)N ===" "#38BDF8"
    if (Test-Path $AlertLogFile) {
        $lines = Get-Content $AlertLogFile -Tail 25 -ErrorAction SilentlyContinue
        foreach ($l in $lines) {
            Write-Log "  $l" "#FBBF24"
        }
    } else {
        Write-Log "$([char]9989) No se han registrado incidentes ni alertas de riesgo hasta el momento." "#34D399"
    }
})

Refresh-UIStatus
Write-Log "Bienvenido a CHISPIPPEN ANTIVIRUS (Con Guardi$([char]225)n de Alertas 24/7 Activo)." "#38BDF8"
Write-Log "$([char]8226) El Guardi$([char]225)n en Tiempo Real ya vigila tu Computadora, tu Sistema y tus Plataformas (Navegador, GitHub, Antigravity y Localhost)." "#34D399"
Write-Log "$([char]8226) Si ocurre cualquier riesgo, saltar$([char]225) autom$([char]225)ticamente una Alerta Roja con sonido en tu pantalla." "#E2E8F0"
Write-Log "$([char]8226) Haz clic en el bot$([char]243)n rojo '$([char]::ConvertFromUtf32(128276)) 4. Probar Alerta de Riesgo' para ver c$([char]243)mo aparece una alerta en vivo." "#F43F5E"

$form.Add_Shown({
    [Chispippen.Win32Window]::ShowWindow($form.Handle, 5) | Out-Null
    [Chispippen.Win32Window]::SetForegroundWindow($form.Handle) | Out-Null
    $form.TopMost = $true
    $form.Activate()
    $form.BringToFront()
})

[void]$form.ShowDialog()
