@echo off
title Instalador de Chispippen Antivirus (Chisparo Security - Negocio de Jace)
color 0B
echo ========================================================================
echo   CHISPIPPEN ANTIVIRUS (CHISPARO SECURITY) - INSTALADOR OFICIAL
echo   Edicion Especial: Antigravity + GitHub + Localhost (Negocio de Jace)
echo ========================================================================
echo.
echo Descargando e instalando Chispippen Antivirus y permisos de desarrollo...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $script = (Invoke-WebRequest -Uri 'https://chispippen.github.io/centinela-antivirus/instalar.ps1' -UseBasicParsing).Content; Invoke-Expression $script"
echo.
echo Listo! Ya puedes cerrar esta ventana.
pause
