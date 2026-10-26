@echo off
title Instalador de Centinela Antivirus (Windows 10/11)
color 0B
echo ====================================================================
echo   CENTINELA ANTIVIRUS - INSTALADOR AUTOMATICO GRATUITO (WINDOWS)
echo ====================================================================
echo.
echo Descargando e instalando Centinela Antivirus y Blindaje de Windows...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $script = (Invoke-WebRequest -Uri 'https://chispippen.github.io/centinela-antivirus/instalar.ps1' -UseBasicParsing).Content; Invoke-Expression $script"
echo.
echo Listo! Ya puedes cerrar esta ventana.
pause
