#!/bin/bash

# deploy_to_emulator.sh
# Script para construir APK, copiar a Descargas, instalar en emulador y mostrarlo
# Uso: ./deploy_to_emulator.sh

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
ANDROID_SDK="/home/bootcamp/android-sdk"
ADB="$ANDROID_SDK/platform-tools/adb"
EMULATOR="$ANDROID_SDK/emulator/emulator"
EMULATOR_NAME="Pixel_3a_API_34_extension_level_7_x86_64"
PACKAGE_NAME="com.spaceotech.finanzas_familiares"
ACTIVITY_NAME="$PACKAGE_NAME/.MainActivity"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 DEPLOY TO EMULATOR - Finanzas Familiares${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# PASO 1: Construir APK
# ============================================================================
echo -e "${YELLOW}📦 Paso 1/6: Construyendo APK de release...${NC}"
flutter build apk --release

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Error construyendo APK${NC}"
  exit 1
fi
echo -e "${GREEN}✅ APK construido exitosamente${NC}"
echo ""

# ============================================================================
# PASO 2: Copiar APK a Descargas
# ============================================================================
echo -e "${YELLOW}💾 Paso 2/6: Copiando APK a Descargas...${NC}"

# Obtener versión del pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
APK_NAME="finanzas-familiares-v${VERSION}-${TIMESTAMP}.apk"
APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
APK_DEST="$HOME/Descargas/${APK_NAME}"

# Copiar APK
cp "$APK_SOURCE" "$APK_DEST"

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Error copiando APK${NC}"
  exit 1
fi

APK_SIZE=$(du -h "$APK_DEST" | cut -f1)
echo -e "${GREEN}✅ APK copiado: ${APK_NAME} (${APK_SIZE})${NC}"
echo ""

# ============================================================================
# PASO 3: Verificar/Iniciar Emulador
# ============================================================================
echo -e "${YELLOW}📱 Paso 3/6: Verificando emulador...${NC}"

# Verificar si ADB está funcionando
if ! command -v "$ADB" &> /dev/null; then
  echo -e "${RED}❌ ADB no encontrado en $ADB${NC}"
  exit 1
fi

# Verificar si el emulador ya está corriendo
if $ADB devices | grep -q "emulator.*device"; then
  echo -e "${GREEN}✓ Emulador ya está corriendo${NC}"
else
  echo -e "${YELLOW}🚀 Iniciando emulador $EMULATOR_NAME...${NC}"

  # Iniciar emulador en background
  nohup "$EMULATOR" -avd "$EMULATOR_NAME" > /dev/null 2>&1 &
  EMULATOR_PID=$!

  echo -e "${YELLOW}⏳ Esperando que el emulador inicie (máximo 120 segundos)...${NC}"

  # Esperar a que el emulador esté listo
  TIMEOUT=120
  ELAPSED=0
  while [ $ELAPSED -lt $TIMEOUT ]; do
    if $ADB devices | grep -q "emulator.*device"; then
      echo -e "${GREEN}✓ Emulador iniciado y listo${NC}"
      break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))

    # Mostrar progreso cada 10 segundos
    if [ $((ELAPSED % 10)) -eq 0 ]; then
      echo -e "${YELLOW}  ... esperando ($ELAPSED/${TIMEOUT}s)${NC}"
    fi

    if [ $ELAPSED -ge $TIMEOUT ]; then
      echo -e "${RED}❌ Timeout esperando emulador (${TIMEOUT}s)${NC}"
      echo -e "${YELLOW}💡 Tip: Verifica que el emulador $EMULATOR_NAME exista:${NC}"
      echo -e "   $EMULATOR -list-avds"
      exit 1
    fi
  done

  # Esperar 5 segundos adicionales para que el sistema termine de cargar
  echo -e "${YELLOW}⏳ Esperando que el sistema termine de cargar...${NC}"
  sleep 5
fi
echo ""

# ============================================================================
# PASO 4: Instalar APK en Emulador
# ============================================================================
echo -e "${YELLOW}📲 Paso 4/6: Instalando APK en emulador...${NC}"

# Instalar APK con -r (reinstall) para mantener datos
$ADB install -r "$APK_SOURCE"

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Error instalando APK${NC}"
  echo -e "${YELLOW}💡 Tip: Intenta desinstalar primero:${NC}"
  echo -e "   $ADB uninstall $PACKAGE_NAME"
  exit 1
fi

echo -e "${GREEN}✅ APK instalado exitosamente${NC}"
echo ""

# ============================================================================
# PASO 5: Lanzar la Aplicación
# ============================================================================
echo -e "${YELLOW}🚀 Paso 5/6: Lanzando aplicación...${NC}"

# Lanzar la aplicación
$ADB shell am start -n "$ACTIVITY_NAME"

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Error lanzando aplicación${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Aplicación lanzada${NC}"
echo ""

# ============================================================================
# PASO 6: Resumen Final
# ============================================================================
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETADO EXITOSAMENTE${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📦 APK:${NC}        ${APK_NAME}"
echo -e "${BLUE}📂 Ubicación:${NC}  ~/Descargas/"
echo -e "${BLUE}💾 Tamaño:${NC}     ${APK_SIZE}"
echo -e "${BLUE}📱 Emulador:${NC}   ${EMULATOR_NAME}"
echo -e "${BLUE}✨ Estado:${NC}     App iniciada y lista para usar"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Mostrar comandos útiles
echo -e "${YELLOW}💡 Comandos útiles:${NC}"
echo -e "   Ver logs:     $ADB logcat | grep -i flutter"
echo -e "   Reinstalar:   $ADB install -r $APK_SOURCE"
echo -e "   Desinstalar:  $ADB uninstall $PACKAGE_NAME"
echo -e "   Devices:      $ADB devices"
echo ""

exit 0
