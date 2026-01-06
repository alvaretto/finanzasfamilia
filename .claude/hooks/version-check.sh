#!/bin/bash
# Script para detectar y notificar cambios de versión en pubspec.yaml

VERSION_CACHE_FILE="/tmp/finanzas_familiares_last_version"
PUBSPEC_FILE="pubspec.yaml"

# Obtener versión actual
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //')

# Verificar si existe versión cacheada
if [ -f "$VERSION_CACHE_FILE" ]; then
    LAST_VERSION=$(cat "$VERSION_CACHE_FILE")

    if [ "$CURRENT_VERSION" != "$LAST_VERSION" ]; then
        echo "🚀 ¡NUEVA VERSIÓN DETECTADA!"
        echo "   Anterior: $LAST_VERSION"
        echo "   Actual:   $CURRENT_VERSION"
        echo ""
        echo "📝 Recuerda:"
        echo "   - Actualizar CHANGELOG.md"
        echo "   - Crear tag en git: git tag v$CURRENT_VERSION"
        echo "   - Notificar al equipo"
    fi
fi

# Guardar versión actual en cache
echo "$CURRENT_VERSION" > "$VERSION_CACHE_FILE"
