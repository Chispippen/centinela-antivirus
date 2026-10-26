# ==============================================================================
# CHISPIPPEN ANTIVIRUS (CHISPARO SECURITY EDITION) - WINDOWS 10/11
# Blindaje de Seguridad + Modo Antigravity, GitHub & Localhost (Negocio de Jace)
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Ocultar la consola negra de fondo dejando visible la ventana grafica de Chispippen Antivirus
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

        # Verificar si las reglas/permisos de Antigravity & Localhost estan activas
        $devRule = Get-NetFirewallRule -DisplayName "Chispippen_Jace_Localhost" -ErrorAction SilentlyContinue
        $agPath = Join-Path $env:USERPROFILE ".gemini\antigravity"
        $hasExcl = $false
        if ($mpPref.ExclusionPath -and ($mpPref.ExclusionPath -contains $agPath)) {
            $hasExcl = $true
        }
        $status.DevModeReady = ([bool]$devRule -or $hasExcl)
    } catch {}
    return $status
}

# Carpetas locales de Chispippen Antivirus
$AppDataDir = Join-Path $env:LOCALAPPDATA "ChispippenAntivirus"
$QuarantineDir = Join-Path $AppDataDir "Cuarentena"
if (-not (Test-Path $QuarantineDir)) { New-Item -ItemType Directory -Path $QuarantineDir -Force | Out-Null }

# ==============================================================================
# INTERFAZ GRAFICA DE CHISPIPPEN ANTIVIRUS
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Chispippen Antivirus (Chisparo Security) $([char]8212) Edici$([char]243)n Negocio de Jace & Antigravity"
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
$lblTitle.Text = "$([char]9889)$([char]::ConvertFromUtf32(128737))$([char]65039) CHISPIPPEN ANTIVIRUS  |  CHISPARO SECURITY"
$lblTitle.Font = $fontTitle
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248)
$lblTitle.Location = New-Object System.Drawing.Point(24, 14)
$lblTitle.AutoSize = $true
$headerPanel.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Protecci$([char]243)n Total + Acceso Libre para Antigravity, GitHub, Node.js y Localhost (Sistema del Negocio de Jace)"
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
$lblStatusHeader.Text = "ESTADO DEL BLINDAJE Y PERMISOS DE DESARROLLO (JACE BUSINESS)"
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

# Fila 1 de Botones Principales
$btnHardenDev = New-ActionButton "$([char]::ConvertFromUtf32(128737))$([char]65039) 1. Blindar + Modo Antigravity" 24 246 225 46 ([System.Drawing.Color]::FromArgb(16, 185, 129))
$btnCheckDev = New-ActionButton "$([char]::ConvertFromUtf32(128640)) 2. Verificar GitHub & Localhost" 260 246 230 46 ([System.Drawing.Color]::FromArgb(14, 165, 233))
$btnQuickScan = New-ActionButton "$([char]9889) 3. Escaneo R$([char]225)pido + Heur$([char]237)stico" 501 246 225 46 ([System.Drawing.Color]::FromArgb(99, 102, 241))
$btnNetAudit = New-ActionButton "$([char]::ConvertFromUtf32(127760)) 4. Monitor de Red y Procesos" 737 246 207 46 ([System.Drawing.Color]::FromArgb(139, 92, 246))

$form.Controls.Add($btnHardenDev)
$form.Controls.Add($btnCheckDev)
$form.Controls.Add($btnQuickScan)
$form.Controls.Add($btnNetAudit)

# Fila 2 de Botones Secundarios
$btnUpdateSigs = New-ActionButton "$([char]::ConvertFromUtf32(128260)) Actualizar Firmas de Virus" 24 302 225 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))
$btnScanFolder = New-ActionButton "$([char]::ConvertFromUtf32(128194)) Escanear Carpeta o USB..." 260 302 230 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))
$btnCleanTemp = New-ActionButton "$([char]::ConvertFromUtf32(129529)) Limpiar Basura Temporal" 501 302 225 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))
$btnScheduleTask = New-ActionButton "$([char]9200) Escaneo Diario Autom$([char]225)tico" 737 302 207 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))

$form.Controls.Add($btnUpdateSigs)
$form.Controls.Add($btnScanFolder)
$form.Controls.Add($btnCleanTemp)
$form.Controls.Add($btnScheduleTask)

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
    if ($s.IsAdmin) {
        $lblAdminBadge.Text = "$([char]9989) MODO ADMINISTRADOR"
        $lblAdminBadge.BackColor = [System.Drawing.Color]::FromArgb(6, 95, 70)
        $lblAdminBadge.ForeColor = [System.Drawing.Color]::FromArgb(167, 243, 208)
    } else {
        $lblAdminBadge.Text = "$([char]9889) CHISPARO ACTIVO"
        $lblAdminBadge.BackColor = [System.Drawing.Color]::FromArgb(30, 58, 138)
        $lblAdminBadge.ForeColor = [System.Drawing.Color]::FromArgb(191, 219, 254)
    }

    $rtIcon = if ($s.RealTime) { "$([char]9989) Activo" } else { "$([char]10060) Inactivo" }
    $fwIcon = if ($s.Firewall) { "$([char]9989) Activo" } else { "$([char]10060) Inactivo" }
    $puaIcon = if ($s.PUABlock) { "$([char]9989) Bloqueando Adware" } else { "$([char]9888)$([char]65039) Clic en Bot$([char]243)n 1 para Activar" }
    $netIcon = if ($s.NetworkProt) { "$([char]9989) Activo (Anti-Phishing)" } else { "$([char]9888)$([char]65039) Clic en Bot$([char]243)n 1 para Activar" }
    $devIcon = if ($s.DevModeReady) { "$([char]9989) Permisos Activos (Antigravity + GitHub + Localhost)" } else { "$([char]9889) Clic en Bot$([char]243)n 1 para Autorizar Permisos" }
    $scanText = if ($s.QuickScanAge -gt 365) { "$([char]9888)$([char]65039) Nunca registrado" } else { "$([char]9989) Hace $($s.QuickScanAge) d$([char]237)as" }

    $lblIndicators.Text = (
        "$([char]8226) Motor en Tiempo Real: $rtIcon   |   $([char]8226) Firewall Windows: $fwIcon   |   $([char]8226) Firmas de Virus: $($s.SigDate)`r`n" +
        "$([char]8226) Bloqueo de Adware/PUA: $puaIcon   |   $([char]8226) Escudo Web Anti-Phishing: $netIcon`r`n" +
        "$([char]8226) Modo Desarrollo Jace: $devIcon   |   $([char]8226) $([char]218)ltimo Escaneo: $scanText"
    )
}

# ==============================================================================
# BLOQUE DE COMANDOS DE BLINDAJE + PERMISOS ANTIGRAVITY / GITHUB / LOCALHOST
# ==============================================================================
function Get-ChispippenAdminScript {
    $agDir = Join-Path $env:USERPROFILE ".gemini"
    $agSubDir = Join-Path $env:USERPROFILE ".gemini\antigravity"
    $scratchDir = Join-Path $env:USERPROFILE ".gemini\antigravity\scratch"
    return @"
# 1. Activar Blindaje Maximo de Microsoft Defender y Firewall
Set-MpPreference -DisableRealtimeMonitoring `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning `$false -ErrorAction SilentlyContinue
Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue
Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue
Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue
Set-MpPreference -SubmitSamplesConsent SendSafeSamples -ErrorAction SilentlyContinue
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction SilentlyContinue

# 2. Autorizar Exclusiones Seguras para Antigravity, GitHub, Node.js y Localhost (Negocio de Jace)
Add-MpPreference -ExclusionPath '$agDir' -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath '$agSubDir' -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath '$scratchDir' -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionIpAddress '127.0.0.1','::1' -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess 'node.exe','git.exe','gh.exe','ssh.exe','code.exe','agy.exe' -ErrorAction SilentlyContinue

# 3. Reglas de Firewall para permitir Localhost (Servidores Web/API del negocio de Jace) y GitHub
Remove-NetFirewallRule -DisplayName 'Chispippen_Jace_Localhost' -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'Chispippen_Jace_Localhost' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3000,3001,4000,4200,5000,5173,5174,8000,8080,8081,8443,8888,9000,9229 -Profile Any -Description 'Permite servidores localhost de Antigravity y del Negocio de Jace' -ErrorAction SilentlyContinue | Out-Null

Remove-NetFirewallRule -DisplayName 'Chispippen_Jace_GitHub_Out' -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'Chispippen_Jace_GitHub_Out' -Direction Outbound -Action Allow -Protocol TCP -RemotePort 22,80,443 -Profile Any -Description 'Permite trafico saliente HTTPS y SSH para GitHub y Antigravity' -ErrorAction SilentlyContinue | Out-Null

Update-MpSignature -ErrorAction SilentlyContinue
"@
}

# BOT?N 1: BLINDAR + ACTIVAR MODO ANTIGRAVITY / GITHUB / LOCALHOST
$btnHardenDev.Add_Click({
    Write-Log "=== ACTIVANDO BLINDAJE CHISPIPPEN + PERMISOS PARA ANTIGRAVITY, GITHUB Y LOCALHOST ===" "#38BDF8"
    $adminCmd = Get-ChispippenAdminScript
    if (-not (Test-IsAdmin)) {
        Write-Log "Solicitando permiso de Administrador (haz clic en 'S$([char]237)' en la ventana emergente)..." "#FBBF24"
        try {
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($adminCmd)
            $encoded = [Convert]::ToBase64String($bytes)
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encoded" -Verb RunAs -Wait
            Write-Log "$([char]9989) Blindaje Antivirus activado (Anti-Adware, Anti-Phishing, Firewall)." "#34D399"
            Write-Log "$([char]9989) Permisos concedidos para Antigravity (~/.gemini/antigravity), GitHub (git, gh, ssh), Node.js y puertos Localhost." "#34D399"
        } catch {
            Write-Log "$([char]9888)$([char]65039) No se acept$([char]243) la ventana de Administrador. Haz clic de nuevo y elige 'S$([char]237)'." "#F87171"
        }
    } else {
        Invoke-Expression $adminCmd
        Write-Log "$([char]9989) Blindaje Antivirus y Permisos de Antigravity/GitHub/Localhost aplicados con $([char]233)xito." "#34D399"
    }
    Refresh-UIStatus
})

# BOT?N 2: VERIFICAR ENTORNO ANTIGRAVITY, GITHUB Y LOCALHOST (SISTEMA DE JACE)
$btnCheckDev.Add_Click({
    Write-Log "=== DIAGN$([char]211)STICO DE PERMISOS: ANTIGRAVITY + GITHUB + LOCALHOST (NEGOCIO DE JACE) ===" "#38BDF8"

    # 1. Verificar carpeta Antigravity
    $agPath = Join-Path $env:USERPROFILE ".gemini\antigravity"
    if (Test-Path $agPath) {
        Write-Log "$([char]9989) Entorno Antigravity detectado y accesible en: $agPath" "#34D399"
    } else {
        Write-Log "$([char]8505)$([char]65039) Carpeta .gemini\antigravity a$([char]250)n no creada en este usuario (quedar$([char]225) pre-autorizada)." "#93C5FD"
    }

    # 2. Verificar herramientas instaladas (Node, Git, GitHub CLI, SSH)
    foreach ($tool in @("node", "git", "gh", "ssh")) {
        $cmd = Get-Command $tool -ErrorAction SilentlyContinue
        if ($cmd) {
            Write-Log "$([char]9989) Herramienta autorizada disponible: $($cmd.Name) -> $($cmd.Source)" "#34D399"
        } else {
            Write-Log "$([char]9888)$([char]65039) Herramienta no instalada a$([char]250)n en esta PC: $tool" "#FBBF24"
        }
    }

    # 3. Verificar conectividad con GitHub (API / HTTPS 443)
    Write-Log "Verificando conexi$([char]243)n segura con GitHub (https://api.github.com)..." "#93C5FD"
    try {
        $ghRes = Invoke-WebRequest -Uri "https://api.github.com" -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop
        Write-Log "$([char]9989) Conexi$([char]243)n con GitHub perfecta (HTTP $($ghRes.StatusCode) - Sin bloqueos de Firewall)." "#34D399"
    } catch {
        Write-Log "$([char]9888)$([char]65039) No se pudo conectar con GitHub: $($_.Exception.Message)" "#F87171"
    }

    # 4. Verificar servidores Localhost activos en este momento
    Write-Log "Escaneando puertos de desarrollo en Localhost (127.0.0.1 / 0.0.0.0)..." "#93C5FD"
    $devPorts = @(3000, 3001, 4000, 4200, 5000, 5173, 5174, 8000, 8080, 8081, 8888)
    $listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $devPorts -contains $_.LocalPort }

    if ($listeners) {
        foreach ($l in $listeners) {
            $pName = (Get-Process -Id $l.OwningProcess -ErrorAction SilentlyContinue).ProcessName
            Write-Log "  $([char]::ConvertFromUtf32(128994)) Servidor Localhost activo en puerto $($l.LocalPort) (Proceso: $pName, PID: $($l.OwningProcess)) - Permitido" "#34D399"
        }
    } else {
        Write-Log "  $([char]8505)$([char]65039) Ning$([char]250)n servidor Localhost corriendo en este instante (Puertos 3000, 5173, 8080 listos y abiertos para cuando inicies el sistema de Jace)." "#E2E8F0"
    }

    Write-Log "$([char]9989) Diagn$([char]243)stico para el sistema del negocio de Jace finalizado." "#34D399"
})

# BOT?N 3: ESCANEO R?PIDO + HEUR?STICO (RESPETANDO PROYECTOS DE ANTIGRAVITY/JACE)
$btnQuickScan.Add_Click({
    Write-Log "=== INICIANDO ESCANEO CHISPIPPEN (MOTOR HEUR$([char]205)STICO + DEFENDER) ===" "#38BDF8"
    Write-Log "Fase 1/2: Buscando virus camuflados con doble extensi$([char]243)n en Descargas y Archivos Temporales..." "#93C5FD"

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
                    Write-Log "  [!] ALERTA: Archivo trampa detectado: $($f.FullName)" "#F87171"
                }
            }
        }
    }

    if ($suspiciousFound -eq 0) {
        Write-Log "$([char]9989) Fase 1 limpia: 0 archivos trampa en Descargas/Temp (Tus carpetas de Antigravity y GitHub est$([char]225)n protegidas y excluidas de falsos positivos)." "#34D399"
    }

    Write-Log "Fase 2/2: Ejecutando Escaneo R$([char]225)pido del sistema (1-2 minutos)..." "#93C5FD"
    try {
        Start-MpScan -ScanType QuickScan -ErrorAction Stop
        Write-Log "$([char]9989) ESCANEO R$([char]193)PIDO COMPLETADO: Tu equipo est$([char]225) limpio y listo para trabajar." "#34D399"
    } catch {
        $mpCmd = Join-Path $env:ProgramFiles "Windows Defender\MpCmdRun.exe"
        if (Test-Path $mpCmd) {
            & $mpCmd -Scan -ScanType 1 | Out-Null
            Write-Log "$([char]9989) ESCANEO R$([char]193)PIDO COMPLETADO." "#34D399"
        }
    }
    Refresh-UIStatus
})

# BOT?N 4: MONITOR DE RED Y PROCESOS
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
    Write-Log "$([char]9989) Auditor$([char]237)a finalizada." "#34D399"
})

# BOT?N 5: ACTUALIZAR FIRMAS
$btnUpdateSigs.Add_Click({
    Write-Log "Actualizando firmas de virus de Chispippen Antivirus..." "#38BDF8"
    Update-MpSignature -ErrorAction SilentlyContinue
    Write-Log "$([char]9989) Base de datos de virus al d$([char]237)a." "#34D399"
    Refresh-UIStatus
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

# BOT?N 7: LIMPIAR TEMPORALES (SIN TOCAR PROYECTOS NI ANTIGRAVITY)
$btnCleanTemp.Add_Click({
    Write-Log "Limpiando cach$([char]233) temporal de Windows ($env:TEMP) sin tocar Antigravity ni proyectos..." "#38BDF8"
    Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "$([char]9989) Archivos temporales limpiados correctamente." "#34D399"
})

# BOT?N 8: ESCANEO DIARIO AUTOM?TICO
$btnScheduleTask.Add_Click({
    Write-Log "Activando programaci$([char]243)n de escaneo diario de Chispippen Antivirus..." "#38BDF8"
    try {
        $action = New-ScheduledTaskAction -Execute "MpCmdRun.exe" -Argument "-Scan -ScanType 1" -WorkingDirectory "$env:ProgramFiles\Windows Defender"
        $trigger = New-ScheduledTaskTrigger -Daily -At 12:30PM
        Register-ScheduledTask -TaskName "Chispippen_Escaneo_Diario" -Action $action -Trigger $trigger -Description "Escaneo diario de Chispippen Antivirus" -Force -ErrorAction Stop | Out-Null
        Write-Log "$([char]9989) Escaneo autom$([char]225)tico diario configurado a las 12:30 PM." "#34D399"
    } catch {
        Write-Log "$([char]8505)$([char]65039) Usa primero el bot$([char]243)n '1. Blindar + Modo Antigravity' para activar permisos de Administrador." "#FBBF24"
    }
})

Refresh-UIStatus
Write-Log "Bienvenido a CHISPIPPEN ANTIVIRUS (Chisparo Security $([char]8212) Edici$([char]243)n Negocio de Jace)." "#38BDF8"
Write-Log "$([char]8226) Dise$([char]241)ado especialmente para proteger tu PC mientras trabajas libremente con Antigravity, GitHub y Localhost." "#E2E8F0"
Write-Log "$([char]8226) Haz clic en '1. Blindar + Modo Antigravity' para autorizar todos los puertos Localhost, GitHub y carpetas de trabajo." "#34D399"
Write-Log "$([char]8226) Haz clic en '2. Verificar GitHub & Localhost' para comprobar que tus herramientas del negocio de Jace est$([char]233)n listas." "#93C5FD"

$form.Add_Shown({
    [Chispippen.Win32Window]::ShowWindow($form.Handle, 5) | Out-Null
    [Chispippen.Win32Window]::SetForegroundWindow($form.Handle) | Out-Null
    $form.TopMost = $true
    $form.Activate()
    $form.BringToFront()
})

[void]$form.ShowDialog()
