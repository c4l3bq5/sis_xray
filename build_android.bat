@echo off
REM Script para compilar la aplicacion Flutter para Android
REM Genera APK y App Bundle

echo ========================================
echo  Compilacion de sis_xray para Android
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

echo [1/5] Verificando instalacion de Flutter...
flutter --version
echo.

echo [2/5] Limpiando builds anteriores...
flutter clean
echo.

echo [3/5] Obteniendo dependencias...
flutter pub get
echo.

echo [4/5] Compilando APK de release...
flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Fallo la compilacion del APK
    pause
    exit /b 1
)
echo.

echo [5/5] Compilando App Bundle de release...
flutter build appbundle --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Fallo la compilacion del App Bundle
    pause
    exit /b 1
)
echo.

echo ========================================
echo  Compilacion exitosa!
echo ========================================
echo.
echo Archivos generados:
echo.
echo APK:
echo   %CD%\build\app\outputs\flutter-apk\app-release.apk
echo.
echo App Bundle:
echo   %CD%\build\app\outputs\bundle\release\app-release.aab
echo.
echo ========================================
echo.
echo El APK puede instalarse directamente en dispositivos Android.
echo El App Bundle (.aab) es para publicar en Google Play Store.
echo.

pause
