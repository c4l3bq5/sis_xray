@echo off
REM Script maestro para compilar la aplicacion Flutter para todas las plataformas
REM disponibles en Windows (Android y Windows)

echo ========================================
echo  Compilacion completa de sis_xray
echo ========================================
echo.
echo Este script compilara la aplicacion para:
echo  - Android (APK y App Bundle)
echo  - Windows (EXE)
echo.
echo Presiona cualquier tecla para continuar o Ctrl+C para cancelar...
pause >nul
echo.

REM Verificar que Flutter este instalado
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter no esta instalado o no esta en el PATH
    echo.
    echo Por favor instala Flutter desde: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

echo ========================================
echo  PASO 1: Compilando para Android
echo ========================================
echo.
call build_android.bat
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Fallo la compilacion para Android
    echo Abortando compilacion completa...
    pause
    exit /b 1
)

echo.
echo.
echo ========================================
echo  PASO 2: Compilando para Windows
echo ========================================
echo.
call build_windows.bat
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Fallo la compilacion para Windows
    pause
    exit /b 1
)

echo.
echo.
echo ========================================
echo  COMPILACION COMPLETA EXITOSA!
echo ========================================
echo.
echo Todos los ejecutables han sido generados:
echo.
echo ANDROID:
echo   APK: build\app\outputs\flutter-apk\app-release.apk
echo   AAB: build\app\outputs\bundle\release\app-release.aab
echo.
echo WINDOWS:
echo   EXE: build\windows\x64\runner\Release\xray_sis_project.exe
echo.
echo ========================================
echo.

pause
