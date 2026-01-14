#!/bin/bash
# Script para generar AAB y APK con nombres versionados
# Uso: ./scripts/build_release.sh

set -e

# Extraer versión de pubspec.yaml
VERSION_LINE=$(grep "^version:" pubspec.yaml)
VERSION_NAME=$(echo $VERSION_LINE | sed 's/version: //' | cut -d'+' -f1)
VERSION_CODE=$(echo $VERSION_LINE | sed 's/version: //' | cut -d'+' -f2)

echo "=== Building Finanzas Familiares v${VERSION_NAME} (${VERSION_CODE}) ==="

# Build AAB
echo "Building AAB..."
flutter build appbundle --release

# Build APK
echo "Building APK..."
flutter build apk --release

# Crear directorio de releases si no existe
RELEASES_DIR="$HOME/Descargas/finanzas-releases"
mkdir -p "$RELEASES_DIR"

# Copiar con nombres versionados
AAB_NAME="finanzas-familiares-${VERSION_NAME}-${VERSION_CODE}.aab"
APK_NAME="finanzas-familiares-${VERSION_NAME}-${VERSION_CODE}.apk"

cp build/app/outputs/bundle/release/app-release.aab "$RELEASES_DIR/$AAB_NAME"
cp build/app/outputs/flutter-apk/app-release.apk "$RELEASES_DIR/$APK_NAME"

echo ""
echo "=== Build completado ==="
echo "AAB: $RELEASES_DIR/$AAB_NAME"
echo "APK: $RELEASES_DIR/$APK_NAME"
echo ""
ls -lh "$RELEASES_DIR"/*.{aab,apk} 2>/dev/null | tail -10
