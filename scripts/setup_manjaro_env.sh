#!/bin/bash
# =============================================================================
# Finanzas Familiares - Manjaro Environment Setup
# =============================================================================
# Configura FVM (Flutter Version Manager) y AVD para desarrollo aislado
# Host: Manjaro Linux (KDE Plasma)
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

FLUTTER_VERSION="3.27.2"  # Versión estable actual
AVD_NAME="FinanzasEnv"
AVD_DEVICE="pixel_6"
AVD_API="34"

# =============================================================================
# 1. FVM (Flutter Version Manager)
# =============================================================================
setup_fvm() {
    log_info "Verificando FVM..."

    if ! command -v fvm &> /dev/null; then
        log_warn "FVM no encontrado. Instalando..."

        # Instalar via dart pub (requiere Dart SDK)
        if command -v dart &> /dev/null; then
            dart pub global activate fvm
        else
            log_error "Dart SDK no encontrado. Instala Flutter primero:"
            echo "  yay -S flutter"
            exit 1
        fi
    fi

    log_success "FVM instalado: $(fvm --version)"

    # Configurar versión de Flutter para el proyecto
    log_info "Configurando Flutter $FLUTTER_VERSION para el proyecto..."

    if [ ! -f ".fvmrc" ]; then
        fvm install "$FLUTTER_VERSION"
        fvm use "$FLUTTER_VERSION"
        log_success "Flutter $FLUTTER_VERSION configurado"
    else
        log_info "FVM ya configurado, usando versión existente"
        fvm install
    fi

    # Verificar
    log_info "Versión activa:"
    fvm flutter --version
}

# =============================================================================
# 2. KVM y Android Emulator
# =============================================================================
check_kvm() {
    log_info "Verificando KVM..."

    if ! lsmod | grep -q kvm; then
        log_error "KVM no está cargado. Ejecuta:"
        echo "  sudo modprobe kvm"
        echo "  sudo modprobe kvm_intel  # o kvm_amd"
        exit 1
    fi

    if ! groups | grep -q kvm; then
        log_warn "Usuario no está en grupo kvm. Ejecuta:"
        echo "  sudo usermod -aG kvm $USER"
        echo "  # Luego cierra sesión y vuelve a entrar"
    fi

    log_success "KVM disponible"
}

setup_android_sdk() {
    log_info "Verificando Android SDK..."

    # Detectar ANDROID_HOME
    if [ -z "$ANDROID_HOME" ]; then
        if [ -d "$HOME/Android/Sdk" ]; then
            export ANDROID_HOME="$HOME/Android/Sdk"
        elif [ -d "/opt/android-sdk" ]; then
            export ANDROID_HOME="/opt/android-sdk"
        else
            log_error "ANDROID_HOME no configurado. Instala Android Studio o SDK."
            exit 1
        fi
    fi

    log_success "ANDROID_HOME: $ANDROID_HOME"

    # Verificar herramientas
    SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    AVDMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
    EMULATOR="$ANDROID_HOME/emulator/emulator"

    if [ ! -f "$SDKMANAGER" ]; then
        # Buscar en ubicación alternativa
        SDKMANAGER="$ANDROID_HOME/tools/bin/sdkmanager"
    fi

    if [ ! -f "$AVDMANAGER" ]; then
        AVDMANAGER="$ANDROID_HOME/tools/bin/avdmanager"
    fi
}

create_avd() {
    log_info "Configurando AVD: $AVD_NAME..."

    setup_android_sdk

    # Verificar si ya existe
    if "$EMULATOR" -list-avds 2>/dev/null | grep -q "$AVD_NAME"; then
        log_success "AVD '$AVD_NAME' ya existe"
        return 0
    fi

    log_info "Instalando system image API $AVD_API..."
    yes | "$SDKMANAGER" "system-images;android-$AVD_API;google_apis_playstore;x86_64" || true

    log_info "Creando AVD..."
    echo "no" | "$AVDMANAGER" create avd \
        --name "$AVD_NAME" \
        --package "system-images;android-$AVD_API;google_apis_playstore;x86_64" \
        --device "$AVD_DEVICE" \
        --force

    # Configurar para mejor rendimiento
    AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
    if [ -f "$AVD_CONFIG" ]; then
        log_info "Optimizando configuración AVD..."
        sed -i 's/hw.ramSize=.*/hw.ramSize=4096/' "$AVD_CONFIG" 2>/dev/null || true
        sed -i 's/vm.heapSize=.*/vm.heapSize=512/' "$AVD_CONFIG" 2>/dev/null || true
        echo "hw.keyboard=yes" >> "$AVD_CONFIG"
        echo "hw.gpu.enabled=yes" >> "$AVD_CONFIG"
        echo "hw.gpu.mode=auto" >> "$AVD_CONFIG"
    fi

    log_success "AVD '$AVD_NAME' creado correctamente"
}

# =============================================================================
# 3. Verificación Final
# =============================================================================
verify_setup() {
    log_info "=== Verificación Final ==="

    echo ""
    log_info "Flutter (via FVM):"
    fvm flutter doctor -v | head -20

    echo ""
    log_info "AVDs disponibles:"
    "$ANDROID_HOME/emulator/emulator" -list-avds 2>/dev/null || echo "  (ninguno)"

    echo ""
    log_success "=== Setup Completado ==="
    echo ""
    echo "Comandos útiles:"
    echo "  fvm flutter run          # Ejecutar app"
    echo "  fvm flutter test         # Ejecutar tests"
    echo "  \$ANDROID_HOME/emulator/emulator -avd $AVD_NAME  # Iniciar emulador"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo "=============================================="
    echo " Finanzas Familiares - Setup Manjaro"
    echo "=============================================="
    echo ""

    cd "$(dirname "$0")/.."

    setup_fvm
    echo ""
    check_kvm
    echo ""
    create_avd
    echo ""
    verify_setup
}

main "$@"
