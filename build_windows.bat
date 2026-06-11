@echo off
REM Script para compilar la aplicacion Flutter para Windows
REM Genera ejecutable .exe

echo ========================================
echo  Compilacion de sis_xray para Windows
echo ========================================
echo.

REM Verificar que Flutter este instalado
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter no esta instalado o no esta en el PATH
    echo.
    echo Por favor instala Flutter desde: https://flutter.dev/docs/get-started/install/windows
    echo O agrega Flutter al PATH del sistema
    pause
    exit /b 1
)

echo [1/4] Verificando instalacion de Flutter...
flutter --version
echo.

echo [2/4] Limpiando builds anteriores...
flutter clean
echo.

echo [3/4] Obteniendo dependencias...
flutter pub get
echo.

echo [4/4] Compilando ejecutable de Windows...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Fallo la compilacion para Windows
    pause
    exit /b 1
)
echo.

echo ========================================
echo  Compilacion exitosa!
echo ========================================
echo.
echo Ejecutable generado en:
echo   %CD%\build\windows\x64\runner\Release\
echo.
echo Archivos principales:
echo   - xray_sis_project.exe (ejecutable principal)
echo   - data\ (carpeta con recursos)
echo   - *.dll (bibliotecas necesarias)
echo.
echo ========================================
echo.
echo IMPORTANTE: Para distribuir la aplicacion, debes copiar
echo toda la carpeta Release\ que contiene el .exe y sus dependencias.
echo.

pause
