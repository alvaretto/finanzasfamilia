#!/bin/bash

# smart_push.sh
# Script para commit inteligente y push a rama principal
# Uso: ./smart_push.sh

set -e  # Exit on error

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 SMART PUSH - Finanzas Familiares${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# Verificar que estamos en un repositorio Git
# ============================================================================
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}❌ Error: No estás en un repositorio Git${NC}"
  exit 1
fi

# ============================================================================
# Obtener información del repositorio
# ============================================================================
CURRENT_BRANCH=$(git branch --show-current)
MODIFIED_FILES=$(git diff --name-only | wc -l)
STAGED_FILES=$(git diff --cached --name-only | wc -l)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard | wc -l)
TOTAL_CHANGES=$((MODIFIED_FILES + STAGED_FILES + UNTRACKED_FILES))

echo -e "${CYAN}📊 Estado del Repositorio${NC}"
echo -e "   Rama: ${MAGENTA}$CURRENT_BRANCH${NC}"
echo -e "   Archivos modificados: ${YELLOW}$MODIFIED_FILES${NC}"
echo -e "   Archivos staged: ${YELLOW}$STAGED_FILES${NC}"
echo -e "   Archivos nuevos: ${YELLOW}$UNTRACKED_FILES${NC}"
echo -e "   Total de cambios: ${YELLOW}$TOTAL_CHANGES${NC}"
echo ""

# Verificar si hay cambios
if [ $TOTAL_CHANGES -eq 0 ]; then
  echo -e "${YELLOW}⚠️  No hay cambios para commitear${NC}"
  exit 0
fi

# ============================================================================
# Analizar cambios para determinar tipo de commit
# ============================================================================
echo -e "${CYAN}🔍 Analizando cambios...${NC}"

# Obtener lista de archivos modificados y nuevos
ALL_FILES=$(git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard)

# Detectar tipo de commit
COMMIT_TYPE="chore"
COMMIT_SCOPE=""
COMMIT_DESC=""

# Análisis de patrones
if echo "$ALL_FILES" | grep -q "^lib/.*\.dart$"; then
  # Cambios en código Dart
  if echo "$ALL_FILES" | grep -q "^lib/features/"; then
    # Cambios en features
    FEATURE=$(echo "$ALL_FILES" | grep "^lib/features/" | head -1 | cut -d'/' -f3)
    COMMIT_SCOPE="$FEATURE"

    # Verificar si son archivos nuevos
    if git ls-files --others --exclude-standard | grep -q "^lib/"; then
      COMMIT_TYPE="feat"
    else
      COMMIT_TYPE="fix"
    fi
  elif echo "$ALL_FILES" | grep -q "^lib/core/"; then
    COMMIT_SCOPE="core"
    COMMIT_TYPE="refactor"
  elif echo "$ALL_FILES" | grep -q "^lib/shared/"; then
    COMMIT_SCOPE="shared"
    COMMIT_TYPE="refactor"
  fi
elif echo "$ALL_FILES" | grep -q "^test/"; then
  # Cambios en tests
  COMMIT_TYPE="test"
  if echo "$ALL_FILES" | grep -q "^test/regression/"; then
    COMMIT_SCOPE="regression"
  elif echo "$ALL_FILES" | grep -q "^test/e2e/"; then
    COMMIT_SCOPE="e2e"
  elif echo "$ALL_FILES" | grep -q "^test/unit/"; then
    COMMIT_SCOPE="unit"
  fi
elif echo "$ALL_FILES" | grep -q "\.md$"; then
  # Cambios en documentación
  COMMIT_TYPE="docs"
  if echo "$ALL_FILES" | grep -q "^\.claude/"; then
    COMMIT_SCOPE="claude"
  fi
elif echo "$ALL_FILES" | grep -q "^\.claude/commands/"; then
  # Nuevos comandos
  COMMIT_TYPE="feat"
  COMMIT_SCOPE="commands"
fi

# Generar descripción basada en archivos
if [ -z "$COMMIT_DESC" ]; then
  # Intentar generar descripción inteligente
  if echo "$ALL_FILES" | grep -q "emulador"; then
    COMMIT_DESC="Configuración de emulador y deployment"
  elif echo "$ALL_FILES" | grep -q "test"; then
    COMMIT_DESC="Actualizar suite de tests"
  elif echo "$ALL_FILES" | grep -q "widget"; then
    COMMIT_DESC="Actualizar widgets y componentes UI"
  elif echo "$ALL_FILES" | grep -q "error-tracker"; then
    COMMIT_DESC="Actualizar error tracking system"
  else
    COMMIT_DESC="Actualizar proyecto"
  fi
fi

echo -e "   ${GREEN}✓${NC} Detectado: ${MAGENTA}$COMMIT_TYPE${NC}"
if [ -n "$COMMIT_SCOPE" ]; then
  echo -e "   ${GREEN}✓${NC} Scope: ${MAGENTA}$COMMIT_SCOPE${NC}"
fi
echo -e "   ${GREEN}✓${NC} Descripción: ${CYAN}$COMMIT_DESC${NC}"
echo ""

# ============================================================================
# Generar mensaje de commit
# ============================================================================
echo -e "${CYAN}📝 Generando mensaje de commit...${NC}"

# Título
if [ -n "$COMMIT_SCOPE" ]; then
  COMMIT_TITLE="${COMMIT_TYPE}(${COMMIT_SCOPE}): ${COMMIT_DESC}"
else
  COMMIT_TITLE="${COMMIT_TYPE}: ${COMMIT_DESC}"
fi

# Obtener estadísticas
STATS=$(git diff --stat 2>/dev/null || echo "")
if [ -n "$STATS" ]; then
  ADDITIONS=$(echo "$STATS" | tail -1 | grep -oP '\d+(?= insertion)' || echo "0")
  DELETIONS=$(echo "$STATS" | tail -1 | grep -oP '\d+(?= deletion)' || echo "0")
else
  ADDITIONS="0"
  DELETIONS="0"
fi

# Listar archivos modificados
MODIFIED_LIST=$(git diff --name-only; git diff --cached --name-only)
NEW_LIST=$(git ls-files --others --exclude-standard)

# Construir mensaje completo
COMMIT_MSG="${COMMIT_TITLE}

## Cambios

"

if [ -n "$MODIFIED_LIST" ]; then
  MODIFIED_COUNT=$(echo "$MODIFIED_LIST" | wc -l)
  COMMIT_MSG+="### Archivos Modificados (${MODIFIED_COUNT})
"
  while IFS= read -r file; do
    COMMIT_MSG+="- $file
"
  done <<< "$MODIFIED_LIST"
  COMMIT_MSG+="
"
fi

if [ -n "$NEW_LIST" ]; then
  NEW_COUNT=$(echo "$NEW_LIST" | wc -l)
  COMMIT_MSG+="### Archivos Nuevos (${NEW_COUNT})
"
  while IFS= read -r file; do
    COMMIT_MSG+="- $file
"
  done <<< "$NEW_LIST"
  COMMIT_MSG+="
"
fi

COMMIT_MSG+="## Estadísticas
+${ADDITIONS} -${DELETIONS} líneas

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# ============================================================================
# Mostrar preview del commit
# ============================================================================
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📋 PREVIEW DEL MENSAJE DE COMMIT${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "$COMMIT_MSG"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# Confirmación del usuario
# ============================================================================
read -p "❓ ¿Commitear estos cambios? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
  echo -e "${YELLOW}⚠️  Commit cancelado${NC}"
  exit 0
fi

# ============================================================================
# Stage y commit
# ============================================================================
echo ""
echo -e "${CYAN}📦 Staging cambios...${NC}"

# Add todos los archivos (modificados y nuevos)
git add -A

COMMIT_HASH=$(git commit -m "$COMMIT_MSG" --no-verify 2>&1 | grep -oP '\[.*?\s+\K[a-f0-9]+' | head -1 || echo "")

if [ -z "$COMMIT_HASH" ]; then
  # Intento alternativo para obtener el hash
  COMMIT_HASH=$(git log -1 --format="%h")
fi

echo -e "${GREEN}✅ Cambios commiteados${NC} (commit: ${MAGENTA}$COMMIT_HASH${NC})"
echo ""

# ============================================================================
# Push
# ============================================================================
read -p "❓ ¿Hacer push a origin/$CURRENT_BRANCH? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
  echo -e "${YELLOW}⚠️  Push cancelado. Commit guardado localmente.${NC}"
  exit 0
fi

# Preguntar sobre force push
echo ""
echo -e "${RED}⚠️  ADVERTENCIA: Force push sobrescribirá el historial remoto${NC}"
read -p "❓ ¿Push forzoso? (s/N): " -n 1 -r
echo ""
FORCE_PUSH=false
if [[ $REPLY =~ ^[SsYy]$ ]]; then
  FORCE_PUSH=true
  echo -e "${RED}⚠️  Confirmación adicional requerida${NC}"
  read -p "❓ ¿Estás SEGURO de hacer force push? (s/N): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    FORCE_PUSH=false
    echo -e "${YELLOW}⚠️  Force push cancelado. Intentando push normal...${NC}"
  fi
fi

# Ejecutar push
echo ""
echo -e "${CYAN}🚀 Pusheando a origin/$CURRENT_BRANCH...${NC}"

if [ "$FORCE_PUSH" = true ]; then
  git push --force origin "$CURRENT_BRANCH"
  echo -e "${GREEN}✅ Force push completado exitosamente${NC}"
else
  if git push origin "$CURRENT_BRANCH" 2>&1 | tee /tmp/git_push_output.txt; then
    echo -e "${GREEN}✅ Push completado exitosamente${NC}"
  else
    # Verificar si falló por divergencia
    if grep -q "rejected" /tmp/git_push_output.txt; then
      echo ""
      echo -e "${RED}❌ Push rechazado: El remoto tiene commits que no tienes localmente${NC}"
      echo ""
      echo -e "${YELLOW}Opciones:${NC}"
      echo -e "  1. ${CYAN}git pull --rebase${NC} - Traer cambios remotos y reorganizar tu commit encima"
      echo -e "  2. ${CYAN}git push --force${NC} - Sobrescribir el remoto (PELIGROSO)"
      echo -e "  3. Cancelar y revisar manualmente"
      echo ""
      exit 1
    else
      echo -e "${RED}❌ Error en push${NC}"
      exit 1
    fi
  fi
fi

# ============================================================================
# Resumen final
# ============================================================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ PUSH COMPLETADO${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📊 Resumen:${NC}"
echo -e "   Commit: ${MAGENTA}$COMMIT_HASH${NC}"
echo -e "   Tipo: ${MAGENTA}$COMMIT_TYPE${NC}"
echo -e "   Rama: ${MAGENTA}$CURRENT_BRANCH${NC}"
echo -e "   Archivos: ${YELLOW}$TOTAL_CHANGES${NC}"
echo -e "   Push: ${GREEN}Exitoso${NC}"
echo ""
echo -e "${YELLOW}💡 Ver último commit:${NC} git log -1"
echo -e "${YELLOW}💡 Ver commits recientes:${NC} git log --oneline -5"
echo ""

exit 0
