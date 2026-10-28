# ==============================================================================
# CHISPIPPEN GUARDIAN - SISTEMA DE ALERTAS EN TIEMPO REAL (24/7)
# Vigila: Computadora (Archivos/Virus), Sistema (Defensas/Procesos) y Plataformas
# ==============================================================================

param(
    [switch]$TestAlert
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Ocultar ventana de consola de fondo si existe
Add-Type -Name Win32Guardian -Namespace Chispippen -MemberDefinition '
    [DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
' -ErrorAction SilentlyContinue
$cPtr = [Chispippen.Win32Guardian]::GetConsoleWindow()
if ($cPtr -ne [IntPtr]::Zero) {
    [Chispippen.Win32Guardian]::ShowWindow($cPtr, 0) | Out-Null
}

[System.Windows.Forms.Application]::EnableVisualStyles()

$AppDataDir = Join-Path $env:LOCALAPPDATA "ChispippenAntivirus"
$LogsDir = Join-Path $AppDataDir "Logs"
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$AlertLogFile = Join-Path $LogsDir "alertas.log"

function Write-AlertLog($category, $title, $detail) {
    $ts = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
    $line = "[$ts] [$category] $title - $detail"
    Add-Content -Path $AlertLogFile -Value $line -ErrorAction SilentlyContinue
}

# ==============================================================================
# VENTANA EMERGENTE DE ALERTA DE RIESGO (POPUP ROJO/AMBAR AL FRENTE DE TODO)
# ==============================================================================
function Show-ChispippenAlert {
    param(
        [string]$Category = "SISTEMA Y PLATAFORMAS",
        [string]$Title = "Riesgo de Seguridad Detectado",
        [string]$Detail = "Se detect$([char]243) una actividad inusual en tu equipo.",
        [string]$Recommendation = "Chispippen Antivirus bloque$([char]243) o aisl$([char]243) la actividad. Revisa el panel principal.",
        [string]$Severity = "ALTA" # ALTA, MEDIA, PRUEBA
    )

    Write-AlertLog $Category $Title $Detail
    [System.Media.SystemSounds]::Exclamation.Play()

    $alertForm = New-Object System.Windows.Forms.Form
    $alertForm.Text = "$([char]::ConvertFromUtf32(128680)) ALERTA DE SEGURIDAD - CHISPIPPEN ANTIVIRUS"
    $alertForm.Size = New-Object System.Drawing.Size(580, 340)
    $alertForm.StartPosition = "CenterScreen"
    $alertForm.BackColor = [System.Drawing.Color]::FromArgb(20, 16, 28)
    $alertForm.ForeColor = [System.Drawing.Color]::White
    $alertForm.FormBorderStyle = "FixedDialog"
    $alertForm.MaximizeBox = $false
    $alertForm.MinimizeBox = $false
    $alertForm.TopMost = $true

    $bannerColor = if ($Severity -eq "ALTA") {
        [System.Drawing.Color]::FromArgb(185, 28, 28)
    } elseif ($Severity -eq "PRUEBA") {
        [System.Drawing.Color]::FromArgb(2, 132, 199)
    } else {
        [System.Drawing.Color]::FromArgb(180, 83, 9)
    }

    $topBar = New-Object System.Windows.Forms.Panel
    $topBar.Size = New-Object System.Drawing.Size(580, 68)
    $topBar.Location = New-Object System.Drawing.Point(0, 0)
    $topBar.BackColor = $bannerColor
    $alertForm.Controls.Add($topBar)

    $lblHeader = New-Object System.Windows.Forms.Label
    $lblHeader.Text = "$([char]9888)$([char]65039) ALERTA DE CHISPIPPEN ANTIVIRUS ($Severity)"
    $lblHeader.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $lblHeader.ForeColor = [System.Drawing.Color]::White
    $lblHeader.Location = New-Object System.Drawing.Point(18, 10)
    $lblHeader.AutoSize = $true
    $topBar.Controls.Add($lblHeader)

    $lblCat = New-Object System.Windows.Forms.Label
    $lblCat.Text = "$([char]193)rea protegida: $Category"
    $lblCat.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
    $lblCat.ForeColor = [System.Drawing.Color]::FromArgb(254, 226, 226)
    $lblCat.Location = New-Object System.Drawing.Point(20, 38)
    $lblCat.AutoSize = $true
    $topBar.Controls.Add($lblCat)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $Title
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11.5, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(248, 113, 113)
    if ($Severity -eq "PRUEBA") { $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(56, 189, 248) }
    $lblTitle.Location = New-Object System.Drawing.Point(20, 82)
    $lblTitle.Size = New-Object System.Drawing.Size(530, 28)
    $alertForm.Controls.Add($lblTitle)

    $txtBody = New-Object System.Windows.Forms.TextBox
    $txtBody.Multiline = $true
    $txtBody.ReadOnly = $true
    $txtBody.BorderStyle = "None"
    $txtBody.BackColor = [System.Drawing.Color]::FromArgb(30, 27, 46)
    $txtBody.ForeColor = [System.Drawing.Color]::FromArgb(226, 232, 240)
    $txtBody.Font = New-Object System.Drawing.Font("Segoe UI", 9.8, [System.Drawing.FontStyle]::Regular)
    $txtBody.Location = New-Object System.Drawing.Point(20, 114)
    $txtBody.Size = New-Object System.Drawing.Size(525, 115)
    $txtBody.Text = "DETALLE DEL RIESGO:`r`n$Detail`r`n`r`nACCI$([char]211)N DE PROTECCI$([char]211)N:`r`n$Recommendation"
    $alertForm.Controls.Add($txtBody)

    $btnOpenPanel = New-Object System.Windows.Forms.Button
    $btnOpenPanel.Text = "$([char]::ConvertFromUtf32(128737))$([char]65039) Abrir Chispippen Antivirus"
    $btnOpenPanel.Location = New-Object System.Drawing.Point(20, 246)
    $btnOpenPanel.Size = New-Object System.Drawing.Size(250, 40)
    $btnOpenPanel.FlatStyle = "Flat"
    $btnOpenPanel.FlatAppearance.BorderSize = 0
    $btnOpenPanel.BackColor = [System.Drawing.Color]::FromArgb(14, 165, 233)
    $btnOpenPanel.ForeColor = [System.Drawing.Color]::White
    $btnOpenPanel.Font = New-Object System.Drawing.Font("Segoe UI", 9.8, [System.Drawing.FontStyle]::Bold)
    $btnOpenPanel.Add_Click({
        $mainApp = Join-Path $AppDataDir "Chispippen-Antivirus.ps1"
        if (Test-Path $mainApp) {
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$mainApp`""
        }
        $alertForm.Close()
    })
    $alertForm.Controls.Add($btnOpenPanel)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "$([char]9989) Entendido (Mantener Vigilancia)"
    $btnOk.Location = New-Object System.Drawing.Point(285, 246)
    $btnOk.Size = New-Object System.Drawing.Size(260, 40)
    $btnOk.FlatStyle = "Flat"
    $btnOk.FlatAppearance.BorderSize = 0
    $btnOk.BackColor = [System.Drawing.Color]::FromArgb(16, 185, 129)
    $btnOk.ForeColor = [System.Drawing.Color]::White
    $btnOk.Font = New-Object System.Drawing.Font("Segoe UI", 9.8, [System.Drawing.FontStyle]::Bold)
    $btnOk.Add_Click({ $alertForm.Close() })
    $alertForm.Controls.Add($btnOk)

    $alertForm.Add_Shown({
        [Chispippen.Win32Guardian]::ShowWindow($alertForm.Handle, 5) | Out-Null
        [Chispippen.Win32Guardian]::SetForegroundWindow($alertForm.Handle) | Out-Null
        $alertForm.TopMost = $true
        $alertForm.Activate()
    })

    [void]$alertForm.ShowDialog()
}

# Si se llamo solo para probar la alerta inmediatamente:
if ($TestAlert) {
    Show-ChispippenAlert `
        -Category "COMPUTADORA, SISTEMA Y PLATAFORMAS (MODO PRUEBA)" `
        -Title "$([char]9989) Sistema de Alertas de Chispippen Antivirus Activo" `
        -Detail "Esta es una alerta de prueba en vivo. Cuando tu computadora, el sistema de Windows o cualquiera de tus plataformas (Navegador Chrome/Edge, GitHub, WhatsApp Web, Antigravity o Localhost del negocio de Jace) corra alg$([char]250)n riesgo, ver$([char]225)s este aviso inmediato en pantalla con sonido." `
        -Recommendation "El Guardi$([char]225)n en Tiempo Real ya est$([char]225) vigilando en segundo plano tus descargas, procesos, red, archivo hosts y defensas del sistema." `
        -Severity "PRUEBA"
    exit
}

# Evitar instancias duplicadas del Guardian en segundo plano
$myPid = $PID
$existing = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessId -ne $myPid -and $_.CommandLine -match 'Chispippen-Guardian\.ps1' -and $_.CommandLine -notmatch '-TestAlert' }
if ($existing) {
    exit
}

# ==============================================================================
# ICONO EN LA BANDEJA DEL SISTEMA (JUNTO AL RELOJ DE WINDOWS)
# ==============================================================================
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Icon = [System.Drawing.SystemIcons]::Shield
$trayIcon.Text = "Chispippen Antivirus: Guardi$([char]225)n de Alertas Activo"
$trayIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$itemOpen = $contextMenu.Items.Add("$([char]::ConvertFromUtf32(128737))$([char]65039) Abrir Panel Chispippen Antivirus")
$itemTest = $contextMenu.Items.Add("$([char]::ConvertFromUtf32(128276)) Probar Alerta de Riesgo Ahora")
$contextMenu.Items.Add("-") | Out-Null
$itemExit = $contextMenu.Items.Add("$([char]10060) Pausar Guardi$([char]225)n de Alertas")

$itemOpen.Add_Click({
    $mainApp = Join-Path $AppDataDir "Chispippen-Antivirus.ps1"
    if (Test-Path $mainApp) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$mainApp`""
    }
})

$itemTest.Add_Click({
    Show-ChispippenAlert `
        -Category "COMPUTADORA, SISTEMA Y PLATAFORMAS" `
        -Title "$([char]9989) Alerta de Prueba: Guardi$([char]225)n Chispippen Funcionando" `
        -Detail "El monitor en tiempo real est$([char]225) supervisando activamente Descargas, Procesos, Red, Navegadores, GitHub y Antigravity." `
        -Recommendation "No se detectan riesgos en este momento. Tu equipo sigue protegido." `
        -Severity "PRUEBA"
})

$itemExit.Add_Click({
    $trayIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

$trayIcon.ContextMenuStrip = $contextMenu
$trayIcon.ShowBalloonTip(5000, "$([char]::ConvertFromUtf32(128737))$([char]65039) Chispippen Guardi$([char]225)n Activo", "Vigilando en tiempo real tu computadora, sistema y plataformas (GitHub, Navegadores, Antigravity).", [System.Windows.Forms.ToolTipIcon]::Info)

# ==============================================================================
# ESTADO BASE PARA DETECCION DE RIESGOS EN TIEMPO REAL
# ==============================================================================
$script:knownThreats = @{}
try {
    $initThreats = Get-MpThreatDetection -ErrorAction SilentlyContinue
    foreach ($t in $initThreats) { $script:knownThreats[$t.DetectionID] = $true }
} catch {}

$script:knownBadFiles = @{}
$script:alertedProcs = @{}
$script:lastDefenderAlert = [DateTime]::MinValue

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$script:hostsHash = ""
if (Test-Path $hostsPath) {
    $script:hostsHash = (Get-FileHash -Path $hostsPath -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
}

# ==============================================================================
# TEMPORIZADOR DE VIGILANCIA CONTINUA (CADA 12 SEGUNDOS)
# ==============================================================================
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 12000 # 12 segundos

$timer.Add_Tick({
    try {
        # 1. VIGILAR MOTOR ANTIVIRUS Y AMENAZAS DETECTADAS EN LA COMPUTADORA
        $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($mp -and (-not $mp.RealTimeProtectionEnabled)) {
            if (((Get-Date) - $script:lastDefenderAlert).TotalMinutes -ge 10) {
                $script:lastDefenderAlert = Get-Date
                $trayIcon.ShowBalloonTip(8000, "$([char]::ConvertFromUtf32(128680)) ALERTA CR$([char]205)TICA: Protecci$([char]243)n Desactivada", "La protecci$([char]243)n en tiempo real fue apagada. Abre Chispippen Antivirus para reactivarla.", [System.Windows.Forms.ToolTipIcon]::Error)
                Show-ChispippenAlert `
                    -Category "SISTEMA OPERATIVO WINDOWS" `
                    -Title "$([char]::ConvertFromUtf32(128680)) La Protecci$([char]243)n en Tiempo Real est$([char]225) Desactivada" `
                    -Detail "El motor de protecci$([char]243)n en tiempo real de tu computadora se encuentra apagado, dejando expuesto el sistema." `
                    -Recommendation "Abre Chispippen Antivirus y haz clic en '1. Blindar + Modo Antigravity' para reactivarlo de inmediato." `
                    -Severity "ALTA"
            }
        }

        $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
        foreach ($t in $threats) {
            if (-not $script:knownThreats.ContainsKey($t.DetectionID)) {
                $script:knownThreats[$t.DetectionID] = $true
                $resList = ($t.Resources -join ", ")
                Show-ChispippenAlert `
                    -Category "COMPUTADORA (AMENAZA DE MALWARE)" `
                    -Title "$([char]::ConvertFromUtf32(128680)) Virus o Amenaza Interceptada en tu Equipo" `
                    -Detail "Se detect$([char]243) e intercept$([char]243) una amenaza activa en: $resList (Dominio/Usuario: $($t.DomainUser))." `
                    -Recommendation "El motor antivirus bloque$([char]243) el archivo autom$([char]225)ticamente. Te recomendamos ejecutar un Escaneo R$([char]225)pido en Chispippen Antivirus." `
                    -Severity "ALTA"
            }
        }

        # 2. VIGILAR DESCARGAS Y ESCRITORIO (ARCHIVOS TRAMPA RECIENTES)
        $watchDirs = @(
            (Join-Path $env:USERPROFILE "Downloads"),
            (Join-Path $env:USERPROFILE "Desktop"),
            (Join-Path $env:USERPROFILE "OneDrive\Desktop")
        ) | Select-Object -Unique

        foreach ($dir in $watchDirs) {
            if (Test-Path $dir) {
                $files = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue
                foreach ($f in $files) {
                    if ($f.Name -match '\.(pdf|doc|docx|xls|xlsx|jpg|png|txt|mp4|zip)\.(exe|scr|bat|cmd|vbs|hta|com|js)$') {
                        if (-not $script:knownBadFiles.ContainsKey($f.FullName)) {
                            $script:knownBadFiles[$f.FullName] = $true
                            Show-ChispippenAlert `
                                -Category "COMPUTADORA (DESCARGA PELIGROSA)" `
                                -Title "$([char]::ConvertFromUtf32(128680)) Archivo Trampa con Doble Extensi$([char]243)n Detectado" `
                                -Detail "Se encontr$([char]243) un archivo ejecutable disfrazado de documento en: $($f.FullName)" `
                                -Recommendation "NO abras ese archivo. Es una t$([char]233)cnica cl$([char]225)sica de virus y robo de cuentas. Elim$([char]237)nalo de inmediato." `
                                -Severity "ALTA"
                        }
                    }
                }
            }
        }

        # 3. VIGILAR PLATAFORMAS WEB Y RED (ARCHIVO HOSTS + PROCESOS ESPIA EN TEMP)
        if (Test-Path $hostsPath) {
            $currHash = (Get-FileHash -Path $hostsPath -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
            if ($script:hostsHash -and $currHash -and ($currHash -ne $script:hostsHash)) {
                $script:hostsHash = $currHash
                Show-ChispippenAlert `
                    -Category "PLATAFORMAS WEB Y NAVEGADORES" `
                    -Title "$([char]9888)$([char]65039) Modificaci$([char]243)n Detectada en el Archivo Hosts de Red" `
                    -Detail "El archivo de redirecci$([char]243)n de sitios web de Windows ($hostsPath) acaba de ser modificado." `
                    -Recommendation "Si t$([char]250) no realizaste este cambio para desarrollo, un programa podr$([char]237)a estar intentando redirigir tus p$([char]225)ginas web o plataformas." `
                    -Severity "MEDIA"
            }
        }

        # Vigilar procesos sospechosos corriendo desde Temp con conexion a Internet
        $netConns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
            Where-Object { $_.RemoteAddress -notmatch '^(127\.|::1|0\.0\.0\.0)' }

        foreach ($c in $netConns) {
            $pidVal = $c.OwningProcess
            if (-not $script:alertedProcs.ContainsKey($pidVal)) {
                $procObj = Get-CimInstance Win32_Process -Filter "ProcessId = $pidVal" -ErrorAction SilentlyContinue
                if ($procObj -and $procObj.ExecutablePath) {
                    $exePath = $procObj.ExecutablePath
                    # Si corre desde Temp o Downloads y no es un instalador firmado conocido
                    if ($exePath -match '\\Temp\\|\\Downloads\\' -and $procObj.Name -notmatch '^(Instalar-Chispippen|powershell|pwsh|git|node|gh|Antigravity)') {
                        $script:alertedProcs[$pidVal] = $true
                        Show-ChispippenAlert `
                            -Category "PLATAFORMAS EN USO Y CONEXI$([char]211)N DE RED" `
                            -Title "$([char]9888)$([char]65039) Proceso en Carpeta Temporal Conectado a Internet" `
                            -Detail "El programa '$($procObj.Name)' ejecut$([char]225)ndose desde '$exePath' abri$([char]243) una conexi$([char]243)n hacia la IP externa $($c.RemoteAddress):$($c.RemotePort)." `
                            -Recommendation "Verifica en Chispippen Antivirus si reconoces este programa. Los virus que roban sesiones suelen ejecutarse desde carpetas temporales." `
                            -Severity "MEDIA"
                    }
                }
            }
        }
    } catch {}
})

$timer.Start()
[System.Windows.Forms.Application]::Run()
