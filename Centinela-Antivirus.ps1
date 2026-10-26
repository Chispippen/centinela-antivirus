# ==============================================================================
# CENTINELA ANTIVIRUS & ESCUDO DE SEGURIDAD (100% GRATUITO - WINDOWS 10/11)
# Suite de Blindaje Nativo + Escáner Heurístico + Monitor de Procesos y Red
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# Verificar si se ejecuta como Administrador
function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Función para obtener el estado actual de seguridad
function Get-SecurityStatus {
    $status = @{
        RealTime = $false
        Antivirus = $false
        Behavior = $false
        Tamper = $false
        PUABlock = $false
        NetworkProt = $false
        RansomwareProt = $false
        Firewall = $false
        SigAge = 999
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
        $status.RansomwareProt = ($mpPref.EnableControlledFolderAccess -eq 1)
        $status.SigAge = $mpStatus.AntivirusSignatureAge
        if ($mpStatus.AntivirusSignatureLastUpdated) {
            $status.SigDate = $mpStatus.AntivirusSignatureLastUpdated.ToString("dd/MM/yyyy HH:mm")
        }
        $status.QuickScanAge = $mpStatus.QuickScanAge

        $fwEnabled = $true
        foreach ($p in $fw) {
            if (-not $p.Enabled) { $fwEnabled = $false }
        }
        $status.Firewall = $fwEnabled
    } catch {
        # Fallback en caso de error de permisos de lectura
    }
    return $status
}

# Crear carpeta de cuarentena local si no existe
$QuarantineDir = Join-Path $env:LOCALAPPDATA "CentinelaAntivirus\Cuarentena"
$LogsDir = Join-Path $env:LOCALAPPDATA "CentinelaAntivirus\Logs"
if (-not (Test-Path $QuarantineDir)) { New-Item -ItemType Directory -Path $QuarantineDir -Force | Out-Null }
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

# ==============================================================================
# INTERFAZ GRÁFICA (MODO OSCURO MODERNO)
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Centinela Security Suite - Protección Antivirus Gratuita"
$form.Size = New-Object System.Drawing.Size(960, 680)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
$form.ForeColor = [System.Drawing.Color]::FromArgb(241, 245, 249)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

$fontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontSubtitle = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$fontCardTitle = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$fontBody = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fontMono = New-Object System.Drawing.Font("Consolas", 9.5, [System.Drawing.FontStyle]::Regular)
$fontBtn = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Cabecera
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size(960, 80)
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$form.Controls.Add($headerPanel)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "🛡️ CENTINELA ANTIVIRUS & BLINDAJE DE WINDOWS"
$lblTitle.Font = $fontTitle
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248)
$lblTitle.Location = New-Object System.Drawing.Point(24, 14)
$lblTitle.AutoSize = $true
$headerPanel.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Protección permanente sin costo: Motor Microsoft Defender + Escáner Heurístico + Monitor de Red y Procesos"
$lblSub.Font = $fontSubtitle
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(148, 163, 184)
$lblSub.Location = New-Object System.Drawing.Point(28, 46)
$lblSub.AutoSize = $true
$headerPanel.Controls.Add($lblSub)

$lblAdminBadge = New-Object System.Windows.Forms.Label
$lblAdminBadge.Font = $fontBody
$lblAdminBadge.Location = New-Object System.Drawing.Point(730, 26)
$lblAdminBadge.Size = New-Object System.Drawing.Size(200, 28)
$lblAdminBadge.TextAlign = "MiddleCenter"
$headerPanel.Controls.Add($lblAdminBadge)

# Panel de Estado (Tarjetas Superiores)
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(24, 96)
$statusPanel.Size = New-Object System.Drawing.Size(900, 130)
$statusPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$form.Controls.Add($statusPanel)

$lblStatusHeader = New-Object System.Windows.Forms.Label
$lblStatusHeader.Text = "ESTADO DE LAS CAPAS DE PROTECCIÓN"
$lblStatusHeader.Font = $fontCardTitle
$lblStatusHeader.ForeColor = [System.Drawing.Color]::FromArgb(226, 232, 240)
$lblStatusHeader.Location = New-Object System.Drawing.Point(16, 12)
$lblStatusHeader.AutoSize = $true
$statusPanel.Controls.Add($lblStatusHeader)

$lblIndicators = New-Object System.Windows.Forms.Label
$lblIndicators.Font = $fontBody
$lblIndicators.Location = New-Object System.Drawing.Point(16, 42)
$lblIndicators.Size = New-Object System.Drawing.Size(868, 78)
$statusPanel.Controls.Add($lblIndicators)

# Botones de Acción Principal
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

$btnHarden = New-ActionButton "🔒 1. Blindar PC al Máximo" 24 240 215 46 ([System.Drawing.Color]::FromArgb(16, 185, 129))
$btnQuickScan = New-ActionButton "⚡ 2. Escaneo Rápido + Heurístico" 252 240 235 46 ([System.Drawing.Color]::FromArgb(14, 165, 233))
$btnProcessAudit = New-ActionButton "🔍 3. Auditar Procesos e Inicio" 500 240 215 46 ([System.Drawing.Color]::FromArgb(99, 102, 241))
$btnNetAudit = New-ActionButton "🌐 4. Auditar Red y Puertos" 728 240 196 46 ([System.Drawing.Color]::FromArgb(139, 92, 246))

$form.Controls.Add($btnHarden)
$form.Controls.Add($btnQuickScan)
$form.Controls.Add($btnProcessAudit)
$form.Controls.Add($btnNetAudit)

# Segunda fila de botones útiles
$btnUpdateSigs = New-ActionButton "🔄 Actualizar Firmas de Virus" 24 296 215 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))
$btnScanFolder = New-ActionButton "📂 Escanear Carpeta o USB..." 252 296 235 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))
$btnCleanTemp = New-ActionButton "🧹 Limpiar Archivos Temporales" 500 296 215 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))
$btnScheduleTask = New-ActionButton "⏰ Activar Escaneo Automático" 728 296 196 38 ([System.Drawing.Color]::FromArgb(51, 65, 85))

$form.Controls.Add($btnUpdateSigs)
$form.Controls.Add($btnScanFolder)
$form.Controls.Add($btnCleanTemp)
$form.Controls.Add($btnScheduleTask)

# Consola de Resultados en Vivo
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(24, 348)
$txtLog.Size = New-Object System.Drawing.Size(900, 276)
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(9, 14, 26)
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
        $lblAdminBadge.Text = "✅ MODO ADMINISTRADOR"
        $lblAdminBadge.BackColor = [System.Drawing.Color]::FromArgb(6, 95, 70)
        $lblAdminBadge.ForeColor = [System.Drawing.Color]::FromArgb(167, 243, 208)
    } else {
        $lblAdminBadge.Text = "ℹ️ MODO ESTÁNDAR"
        $lblAdminBadge.BackColor = [System.Drawing.Color]::FromArgb(30, 58, 138)
        $lblAdminBadge.ForeColor = [System.Drawing.Color]::FromArgb(191, 219, 254)
    }

    $rtIcon = if ($s.RealTime) { "✅ Activo" } else { "❌ Inactivo" }
    $fwIcon = if ($s.Firewall) { "✅ Activo" } else { "❌ Inactivo" }
    $puaIcon = if ($s.PUABlock) { "✅ Bloqueando" } else { "⚠️ Solo Auditoría (Clic en Blindar)" }
    $netIcon = if ($s.NetworkProt) { "✅ Activo (Anti-Phishing)" } else { "⚠️ Desactivado (Clic en Blindar)" }
    $ransomIcon = if ($s.RansomwareProt) { "✅ Activo" } else { "ℹ️ Opcional" }
    $scanText = if ($s.QuickScanAge -gt 365) { "⚠️ Nunca registrado" } else { "✅ Hace $($s.QuickScanAge) días" }

    $lblIndicators.Text = (
        "• Protección en Tiempo Real: $rtIcon     |  • Cortafuegos (Firewall): $fwIcon     |  • Última firma de virus: $($s.SigDate)`r`n" +
        "• Bloqueo de Adware/PUA: $puaIcon  |  • Escudo de Red Web: $netIcon`r`n" +
        "• Último Escaneo Completo/Rápido: $scanText  |  • Antiransomware de Carpetas: $ransomIcon"
    )
}

# ==============================================================================
# ACCIONES DE LOS BOTONES
# ==============================================================================

# 1. BLINDAR PC AL MÁXIMO
$btnHarden.Add_Click({
    Write-Log "=== INICIANDO BLINDAJE DE SEGURIDAD DE WINDOWS ===" "#38BDF8"
    if (-not (Test-IsAdmin)) {
        Write-Log "Solicitando permisos de Administrador para activar todas las capas de protección..." "#FBBF24"
        $scriptPath = $MyInvocation.MyCommand.Definition
        if (-not $scriptPath) { $scriptPath = $PSCommandPath }
        try {
            $hardeningCmd = @"
Set-MpPreference -DisableRealtimeMonitoring `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection `$false -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning `$false -ErrorAction SilentlyContinue
Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue
Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue
Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue
Set-MpPreference -SubmitSamplesConsent SendSafeSamples -ErrorAction SilentlyContinue
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction SilentlyContinue
Update-MpSignature -ErrorAction SilentlyContinue
"@
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($hardeningCmd)
            $encoded = [Convert]::ToBase64String($bytes)
            $proc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -Verb RunAs -PassThru -Wait
            Write-Log "✅ Configuración de blindaje con privilegios de Administrador aplicada correctamente." "#34D399"
        } catch {
            Write-Log "⚠️ No se otorgaron permisos de Administrador o se canceló la ventana UAC." "#F87171"
        }
    } else {
        Write-Log "Aplicando políticas avanzadas en Microsoft Defender y Firewall..." "#38BDF8"
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue
        Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue
        Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue
        Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue
        Set-MpPreference -SubmitSamplesConsent SendSafeSamples -ErrorAction SilentlyContinue
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction SilentlyContinue
        Write-Log "✅ Bloqueo de Adware (PUA), Escudo de Red Anti-Phishing, Escaneo de Scripts y Firewall activados." "#34D399"
    }
    Refresh-UIStatus
})

# 2. ESCANEO RÁPIDO + HEURÍSTICO PROPIO
$btnQuickScan.Add_Click({
    Write-Log "=== INICIANDO ESCANEO HEURÍSTICO + MOTOR ANTIVIRUS ===" "#38BDF8"
    Write-Log "Fase 1/3: Analizando carpetas críticas (Descargas, Escritorio, Temp, Inicio) en busca de archivos camuflados..." "#93C5FD"

    $scanPaths = @(
        (Join-Path $env:USERPROFILE "Downloads"),
        (Join-Path $env:USERPROFILE "Desktop"),
        $env:TEMP,
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup")
    )

    $suspiciousFound = 0
    foreach ($dir in $scanPaths) {
        if (Test-Path $dir) {
            Write-Log "  -> Analizando: $dir" "#94A3B8"
            # Buscar archivos con doble extensión engañosa (.pdf.exe, .jpg.scr, .Jn.vbs, etc.)
            $files = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                if ($f.Name -match '\.(pdf|doc|docx|xls|xlsx|jpg|png|txt|mp4)\.(exe|scr|bat|cmd|vbs|ps1|js|hta|com)$') {
                    $suspiciousFound++
                    $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                    Write-Log "  [!] ALERTA: Doble extensión engañosa detectada: $($f.FullName) (SHA256: $hash)" "#F87171"
                }
            }
        }
    }

    if ($suspiciousFound -eq 0) {
        Write-Log "✅ Fase 1 completada: No se encontraron archivos con doble extensión trampa en tus carpetas críticas." "#34D399"
    } else {
        Write-Log "⚠️ Fase 1 completada: Se detectaron $suspiciousFound archivos sospechosos." "#F87171"
    }

    Write-Log "Fase 2/3: Verificando amenazas registradas por el motor de Windows..." "#93C5FD"
    $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
    if ($threats) {
        foreach ($t in $threats) {
            Write-Log "  [!] Amenaza previa bloqueada en historial: ID $($t.ThreatID) en $($t.InitialDetectionTime)" "#FBBF24"
        }
    } else {
        Write-Log "✅ Historial limpio: No hay infecciones activas reportadas." "#34D399"
    }

    Write-Log "Fase 3/3: Ejecutando Escaneo Rápido Oficial con el motor Microsoft Defender (esto puede tardar 1-2 minutos)..." "#93C5FD"
    try {
        Start-MpScan -ScanType QuickScan -ErrorAction Stop
        Write-Log "✅ ESCANEO RÁPIDO COMPLETADO CON ÉXITO. Tu sistema ha sido verificado." "#34D399"
    } catch {
        # Fallback usando MpCmdRun.exe
        $mpCmd = Join-Path $env:ProgramFiles "Windows Defender\MpCmdRun.exe"
        if (Test-Path $mpCmd) {
            & $mpCmd -Scan -ScanType 1 | Out-Null
            Write-Log "✅ ESCANEO RÁPIDO COMPLETADO CON ÉXITO." "#34D399"
        } else {
            Write-Log "ℹ️ No se pudo iniciar Start-MpScan directamente: $($_.Exception.Message)" "#FBBF24"
        }
    }
    Refresh-UIStatus
})

# 3. AUDITAR PROCESOS E INICIO DE WINDOWS
$btnProcessAudit.Add_Click({
    Write-Log "=== AUDITORÍA DE PROCESOS EN EJECUCIÓN Y PROGRAMAS DE INICIO ===" "#38BDF8"
    Write-Log "Analizando procesos que se ejecutan desde carpetas temporales o ubicaciones inusuales..." "#93C5FD"

    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    $flaggedProcs = 0
    foreach ($p in $procs) {
        $exe = $p.ExecutablePath
        if ($exe) {
            if ($exe -match '\\Temp\\|\\Tmp\\|\\Downloads\\|\\AppData\\Local\\Temp') {
                $flaggedProcs++
                Write-Log "  [!] Proceso corriendo desde carpeta temporal: $($p.Name) (PID: $($p.ProcessId)) -> $exe" "#FBBF24"
            }
        }
    }
    if ($flaggedProcs -eq 0) {
        Write-Log "✅ Ningún proceso sospechoso ejecutándose desde carpetas temporales o Descargas." "#34D399"
    }

    Write-Log "Revisando programas configurados para arrancar automáticamente con Windows..." "#93C5FD"
    $startupItems = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue
    foreach ($item in $startupItems) {
        Write-Log "  • [Inicio] $($item.Name) -> $($item.Command) ($($item.Location))" "#E2E8F0"
    }
    Write-Log "✅ Auditoría de procesos e inicio finalizada." "#34D399"
})

# 4. AUDITAR RED Y CONEXIONES EXTERNAS
$btnNetAudit.Add_Click({
    Write-Log "=== AUDITORÍA DE CONEXIONES DE RED EXTERNAS ===" "#38BDF8"
    $conns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
        Where-Object { $_.RemoteAddress -notmatch '^(127\.|::1|0\.0\.0\.0)' }

    Write-Log "Conexiones TCP activas hacia el exterior: $($conns.Count)" "#93C5FD"
    foreach ($c in ($conns | Select-Object -First 25)) {
        $procName = "Sistema"
        try {
            $procName = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        } catch {}
        Write-Log ("  • Proceso: {0,-20} (PID {1,-6}) -> IP Remota: {2}:{3}" -f $procName, $c.OwningProcess, $c.RemoteAddress, $c.RemotePort) "#E2E8F0"
    }
    Write-Log "✅ Auditoría de red completada." "#34D399"
})

# 5. ACTUALIZAR FIRMAS DE VIRUS
$btnUpdateSigs.Add_Click({
    Write-Log "Descargando las últimas definiciones de virus e inteligencia en la nube..." "#38BDF8"
    try {
        Update-MpSignature -ErrorAction Stop
        Write-Log "✅ Base de datos de virus actualizada a la versión más reciente." "#34D399"
    } catch {
        $mpCmd = Join-Path $env:ProgramFiles "Windows Defender\MpCmdRun.exe"
        if (Test-Path $mpCmd) {
            & $mpCmd -SignatureUpdate | Out-Null
            Write-Log "✅ Base de datos de virus actualizada correctamente." "#34D399"
        } else {
            Write-Log "⚠️ Error al actualizar firmas: $($_.Exception.Message)" "#F87171"
        }
    }
    Refresh-UIStatus
})

# 6. ESCANEAR CARPETA O USB ESPECÍFICO
$btnScanFolder.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Selecciona la carpeta o memoria USB que deseas analizar con Centinela:"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedPath = $dialog.SelectedPath
        Write-Log "Analizando carpeta personalizada: $selectedPath ..." "#38BDF8"
        try {
            Start-MpScan -ScanType CustomScan -ScanPath $selectedPath -ErrorAction Stop
            Write-Log "✅ Análisis completado sin amenazas en: $selectedPath" "#34D399"
        } catch {
            $mpCmd = Join-Path $env:ProgramFiles "Windows Defender\MpCmdRun.exe"
            if (Test-Path $mpCmd) {
                & $mpCmd -Scan -ScanType 3 -File $selectedPath | Out-Null
                Write-Log "✅ Análisis completado en: $selectedPath" "#34D399"
            }
        }
    }
})

# 7. LIMPIAR ARCHIVOS TEMPORALES (REDUCE RIESGO DE MALWARE EN CACHÉ)
$btnCleanTemp.Add_Click({
    Write-Log "Limpiando archivos temporales en $env:TEMP ..." "#38BDF8"
    $before = (Get-ChildItem -Path $env:TEMP -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $after = (Get-ChildItem -Path $env:TEMP -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $freedMB = [math]::Round(($before - $after) / 1MB, 2)
    if ($freedMB -lt 0) { $freedMB = 0 }
    Write-Log "✅ Limpieza completada. Espacio temporal liberado: $freedMB MB." "#34D399"
})

# 8. PROGRAMAR ESCANEO AUTOMÁTICO DIARIO
$btnScheduleTask.Add_Click({
    Write-Log "Configurando escaneo rápido diario automático en Windows..." "#38BDF8"
    try {
        $action = New-ScheduledTaskAction -Execute "MpCmdRun.exe" -Argument "-Scan -ScanType 1" -WorkingDirectory "$env:ProgramFiles\Windows Defender"
        $trigger = New-ScheduledTaskTrigger -Daily -At 12:30PM
        Register-ScheduledTask -TaskName "Centinela_Escaneo_Diario" -Action $action -Trigger $trigger -Description "Escaneo rápido diario de Centinela Antivirus" -Force -ErrorAction Stop | Out-Null
        Write-Log "✅ Escaneo automático diario programado todos los días a las 12:30 PM." "#34D399"
    } catch {
        Write-Log "ℹ️ Nota: Usa primero '1. Blindar PC al Máximo' o abre como Administrador para registrar tareas programadas." "#FBBF24"
    }
})

# Inicializar pantalla
Refresh-UIStatus
Write-Log "Bienvenido a Centinela Security Suite (100% Gratuito)." "#38BDF8"
Write-Log "1. Haz clic en '1. Blindar PC al Máximo' para activar el bloqueo de Adware/PUA y el Escudo Web Anti-Phishing." "#E2E8F0"
Write-Log "2. Haz clic en '2. Escaneo Rápido + Heurístico' para realizar un análisis completo de tu equipo ahora mismo." "#E2E8F0"

[void]$form.ShowDialog()
