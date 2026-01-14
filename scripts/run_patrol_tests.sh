#!/bin/bash
# Script para ejecutar Patrol Tests
# Finanzas Familiares - Self-Healing Visual Testing

set -e

echo "============================================"
echo "  Patrol Tests - Finanzas Familiares"
echo "============================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que existe el emulador
check_emulator() {
    if ! adb devices | grep -q "emulator"; then
        echo -e "${YELLOW}No hay emulador corriendo. Iniciando Pixel_6_API_34...${NC}"
        emulator -avd Pixel_6_API_34 -no-snapshot-load &
        sleep 30
    else
        echo -e "${GREEN}Emulador detectado${NC}"
    fi
}

# Limpiar screenshots anteriores
clean_screenshots() {
    echo "Limpiando screenshots anteriores..."
    rm -rf screenshots/patrol
    mkdir -p screenshots/patrol
}

# Ejecutar tests
run_tests() {
    local test_file=$1

    if [ -z "$test_file" ]; then
        echo "Ejecutando todos los tests de integración..."
        patrol test --target integration_test/
    else
        echo "Ejecutando: $test_file"
        patrol test --target "$test_file"
    fi
}

# Generar reporte
generate_report() {
    echo ""
    echo "============================================"
    echo "  REPORTE DE TESTS"
    echo "============================================"

    # Contar screenshots generados
    local screenshot_count=$(find screenshots/patrol -name "*.png" 2>/dev/null | wc -l)
    echo "Screenshots capturados: $screenshot_count"

    if [ -d "screenshots/patrol" ]; then
        echo ""
        echo "Screenshots guardados en: screenshots/patrol/"
        ls -la screenshots/patrol/ 2>/dev/null || echo "  (vacío)"
    fi
}

# Main
main() {
    echo ""

    case "$1" in
        "app")
            check_emulator
            clean_screenshots
            run_tests "integration_test/app_test.dart"
            ;;
        "explore")
            check_emulator
            clean_screenshots
            run_tests "integration_test/autonomous/exploration_test.dart"
            ;;
        "golden")
            check_emulator
            clean_screenshots
            run_tests "integration_test/golden/visual_regression_test.dart"
            ;;
        "all")
            check_emulator
            clean_screenshots
            run_tests
            ;;
        *)
            echo "Uso: $0 {app|explore|golden|all}"
            echo ""
            echo "  app     - Tests básicos de la aplicación"
            echo "  explore - Exploración autónoma de pantallas"
            echo "  golden  - Tests de regresión visual (Golden)"
            echo "  all     - Ejecutar todos los tests"
            exit 1
            ;;
    esac

    generate_report
}

main "$@"
