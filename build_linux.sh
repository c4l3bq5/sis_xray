#!/bin/bash
# Script para compilar la aplicacion Flutter para Linux
# Genera ejecutable para Linux

echo "========================================"
echo " Compilacion de sis_xray para Linux"
echo "========================================"
echo ""

# Verificar que Flutter este instalado
if ! command -v flutter &> /dev/null; then
    echo "[ERROR] Flutter no esta instalado o no esta en el PATH"
    echo ""
    echo "Por favor instala Flutter desde: https://flutter.dev/docs/get-started/install/linux"
    echo "O agrega Flutter al PATH del sistema"
    exit 1
fi

echo "[1/4] Verificando instalacion de Flutter..."
flutter --version
echo ""

echo "[2/4] Limpiando builds anteriores..."
flutter clean
echo ""

echo "[3/4] Obteniendo dependencias..."
flutter pub get
echo ""

echo "[4/4] Compilando ejecutable de Linux..."
flutter build linux --release
if [ $? -ne 0 ]; then
    echo "[ERROR] Fallo la compilacion para Linux"
    exit 1
fi
echo ""

echo "========================================"
echo " Compilacion exitosa!"
echo "========================================"
echo ""
echo "Ejecutable generado en:"
echo "  $(pwd)/build/linux/x64/release/bundle/"
echo ""
echo "Archivos principales:"
echo "  - xray_sis_project (ejecutable principal)"
echo "  - data/ (carpeta con recursos)"
echo "  - lib/ (bibliotecas necesarias)"
echo ""
echo "========================================"
echo ""
echo "IMPORTANTE: Para distribuir la aplicacion, debes copiar"
echo "toda la carpeta bundle/ que contiene el ejecutable y sus dependencias."
echo ""
