# Guia del Sistema de Error Tracking

Sistema de documentacion acumulativa de errores con generacion automatica de tests de regresion para el proyecto Finanzas Familiares.

## Tabla de Contenidos

1. [Introduccion](#introduccion)
2. [Estructura de Archivos](#estructura-de-archivos)
3. [Workflow Principal](#workflow-principal)
4. [Scripts Disponibles](#scripts-disponibles)
5. [Esquema de Errores](#esquema-de-errores)
6. [Anti-Patrones](#anti-patrones)
7. [Generacion de Tests](#generacion-de-tests)
8. [Deteccion Automatica](#deteccion-automatica)
9. [Mejores Practicas](#mejores-practicas)
10. [Ejemplos](#ejemplos)

---

## Introduccion

El sistema de Error Tracking permite:

- Documentar cada error corregido con contexto completo
- Registrar soluciones que NO funcionan (anti-patrones)
- Detectar automaticamente errores recurrentes
- Generar tests de regresion para evitar reintroducir bugs
- Mantener un historial de conocimiento acumulativo

## Estructura de Archivos

```
.error-tracker/
├── errors/                    # Errores individuales
│   ├── ERR-0001.json
│   ├── ERR-0002.json
│   └── ...
├── scripts/                   # Scripts Python
│   ├── add_error.py           # Agregar/actualizar errores
│   ├── search_errors.py       # Buscar errores similares
│   ├── detect_recurrence.py   # Detectar errores recurrentes
│   ├── mark_failed.py         # Marcar solucion fallida
│   ├── generate_test.py       # Generar test de regresion
│   └── rebuild_index.py       # Regenerar indice
├── patterns.json              # Patrones de deteccion
├── anti-patterns.json         # Soluciones que NO funcionan
└── index.md                   # Indice auto-generado
```

## Workflow Principal

### Al Encontrar un Error

```bash
# 1. ANTES de implementar solucion, buscar errores similares
python .error-tracker/scripts/search_errors.py "mensaje de error aqui"

# 2. Si hay similares, revisar sus soluciones y anti-patrones
# 3. Implementar la solucion

# 4. Documentar el error corregido
python .error-tracker/scripts/add_error.py

# 5. Generar test de regresion
python .error-tracker/scripts/generate_test.py ERR-XXXX

# 6. Ejecutar test para verificar
flutter test test/regression/
```

### Cuando una Solucion Falla

```bash
# 1. Marcar la solucion como fallida
python .error-tracker/scripts/mark_failed.py ERR-XXXX "razon por la que fallo"

# Esto automaticamente:
# - Mueve la solucion a anti-patterns del error
# - Actualiza anti-patterns.json global
# - Cambia el estado a "reopened"
# - Incrementa reopened_count

# 2. Buscar nueva solucion (evitando los anti-patrones)
# 3. Documentar nueva solucion
python .error-tracker/scripts/add_error.py --update ERR-XXXX
```

## Scripts Disponibles

### add_error.py

Agrega nuevo error o actualiza existente.

```bash
# Nuevo error (modo interactivo)
python .error-tracker/scripts/add_error.py

# Actualizar error existente
python .error-tracker/scripts/add_error.py --update ERR-0001
```

El modo interactivo solicita:
- Titulo (breve)
- Descripcion (detallada)
- Severidad (critical/high/medium/low)
- Mensaje de error exacto
- Archivos afectados
- Tags
- Palabras clave para deteccion

### search_errors.py

Busca errores similares por texto, tags o archivo.

```bash
# Busqueda por texto
python .error-tracker/scripts/search_errors.py "RLS policy recursion"

# Con filtro por tag
python .error-tracker/scripts/search_errors.py "error" --tag supabase

# Con filtro por archivo
python .error-tracker/scripts/search_errors.py "provider" --file account_provider.dart
```

Muestra:
- Top 5 resultados con porcentaje de similitud
- Estado y severidad
- Solucion si existe
- Anti-patrones documentados

### detect_recurrence.py

Detecta si un mensaje de error corresponde a uno ya documentado.

```bash
# Por mensaje directo
python .error-tracker/scripts/detect_recurrence.py "infinite recursion in RLS"

# Desde archivo de log
python .error-tracker/scripts/detect_recurrence.py --file error.log
```

Usa:
- Regex de deteccion configurados
- Keywords del error
- Similitud de texto

### mark_failed.py

Marca una solucion como fallida y reabre el error.

```bash
python .error-tracker/scripts/mark_failed.py ERR-0001 "causa efecto secundario en sync"
```

Acciones automaticas:
- Mueve solucion a anti_patterns del error
- Agrega a anti-patterns.json global
- Cambia estado a "reopened"
- Incrementa reopened_count
- Regenera index.md

### generate_test.py

Genera test de regresion basado en el error.

```bash
# Auto-detecta tipo de test
python .error-tracker/scripts/generate_test.py ERR-0001

# Especificar tipo
python .error-tracker/scripts/generate_test.py ERR-0001 --type integration
```

Tipos disponibles:
- **unit**: Para logica de negocio, utils, models
- **widget**: Para screens, components, UI
- **integration**: Para flujos, sync, auth, database

Ubicacion de tests generados:
```
test/regression/
├── unit/{feature}/err_xxxx_regression_test.dart
├── widget/{feature}/err_xxxx_regression_test.dart
└── integration/{feature}/err_xxxx_regression_test.dart
```

### rebuild_index.py

Regenera el indice completo.

```bash
python .error-tracker/scripts/rebuild_index.py
```

Incluye:
- Estadisticas generales
- Errores reabiertos (prioridad maxima)
- Errores criticos abiertos
- Errores resueltos recientes
- Indice por tags
- Comandos rapidos

## Esquema de Errores

Cada error se documenta en JSON con la siguiente estructura:

```json
{
  "id": "ERR-0001",
  "title": "Titulo breve (max 100 chars)",
  "description": "Descripcion detallada",
  "severity": "critical | high | medium | low",
  "status": "open | resolved | reopened | investigating",
  
  "error_details": {
    "message": "Mensaje de error exacto",
    "stack_trace": "Stack trace completo",
    "error_type": "runtime | compile | logic | ui | network | database",
    "reproducibility": "always | sometimes | rare"
  },
  
  "context": {
    "affected_files": [
      {"path": "lib/...", "lines": [45, 67], "function": "fetchData"}
    ],
    "environment": {
      "flutter_version": "3.24.0",
      "platform": "web | android",
      "mode": "debug | release"
    },
    "user_action": "Que estaba haciendo el usuario",
    "prerequisites": "Condiciones para reproducir"
  },
  
  "solution": {
    "summary": "Resumen de la solucion",
    "changes": [
      {
        "file": "lib/...",
        "before": "codigo anterior",
        "after": "codigo corregido",
        "explanation": "Por que funciona"
      }
    ],
    "root_cause": "Causa raiz",
    "applied_at": "2026-01-05T10:30:00Z",
    "verified": true
  },
  
  "anti_patterns": [
    {
      "attempted_solution": "Lo que se intento",
      "why_failed": "Por que no funciono",
      "side_effects": "Efectos secundarios"
    }
  ],
  
  "related_tests": [
    {"path": "test/regression/...", "type": "unit"}
  ],
  
  "metadata": {
    "created_at": "...",
    "updated_at": "...",
    "resolved_at": "...",
    "reopened_count": 0,
    "tags": ["supabase", "rls", "sync"],
    "related_errors": ["ERR-0005"]
  },
  
  "detection_patterns": {
    "error_regex": "regex para detectar",
    "keywords": ["palabras", "clave"],
    "file_patterns": ["**/providers/*.dart"]
  }
}
```

### Tags Predefinidos

**Por Tecnologia:**
- flutter, dart, riverpod, drift, supabase

**Por Area:**
- auth, sync, rls, database, ui, navigation, network

**Por Tipo:**
- performance, memory, crash, logic, ui-glitch

**Por Feature:**
- accounts, transactions, budgets, goals, ai-chat, reports

## Anti-Patrones

Los anti-patrones son soluciones que se intentaron pero NO funcionaron. Son cruciales para:

1. **Evitar repetir errores**: No perder tiempo en soluciones que ya fallaron
2. **Documentar edge cases**: Entender por que ciertas aproximaciones no funcionan
3. **Compartir conocimiento**: Otros desarrolladores aprenden de intentos fallidos

### Estructura Global (anti-patterns.json)

```json
{
  "patterns": [
    {
      "error_id": "ERR-0001",
      "error_title": "RLS Recursion",
      "tags": ["supabase", "rls"],
      "attempted_solution": "Usar SECURITY DEFINER sin materializar",
      "why_failed": "Causa recursion infinita",
      "added_at": "2026-01-05T10:00:00Z"
    }
  ],
  "by_tag": {
    "supabase": ["ERR-0001", "ERR-0015"],
    "rls": ["ERR-0001"]
  },
  "by_error_type": {
    "database": ["ERR-0001"]
  }
}
```

## Generacion de Tests

El script `generate_test.py` crea tests de regresion con:

- Comentarios documentando el error original
- TODOs para completar assertions
- Notas sobre anti-patrones a evitar
- Importaciones sugeridas

### Ejemplo de Test Generado

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/accounts/providers/account_provider.dart';

/// Test de regresion para ERR-0001: RLS Recursion en family_members
/// 
/// Causa raiz: Policy referenciaba a si misma
/// Archivo original: lib/features/accounts/providers/account_provider.dart
void main() {
  group('ERR-0001 Regression', () {
    test('should not exhibit the original error behavior', () {
      // Arrange
      // TODO: Preparar datos de prueba
      
      // Act
      // TODO: Ejecutar la accion que causaba el error
      
      // Assert
      // TODO: Verificar que el error no ocurre
    });
    
    test('should handle edge cases correctly', () {
      // Anti-patrones conocidos - NO hacer:
      // - Usar SECURITY DEFINER sin materializar vista
      // TODO: Agregar casos que verifiquen que no caemos en anti-patrones
    });
  });
}
```

## Deteccion Automatica

El sistema puede detectar errores recurrentes usando:

1. **Regex**: Patrones exactos de mensajes de error
2. **Keywords**: Palabras clave asociadas al error
3. **File patterns**: Archivos tipicamente afectados

Configuracion en cada error (detection_patterns):

```json
{
  "error_regex": "infinite recursion.*RLS",
  "keywords": ["recursion", "policy", "family_members"],
  "file_patterns": ["**/supabase/**", "**/rls/**"]
}
```

## Mejores Practicas

### Al Documentar Errores

1. **Titulo claro**: Que identifique el problema en pocas palabras
2. **Mensaje exacto**: Copiar el mensaje de error completo
3. **Contexto completo**: Que hacia el usuario, que version, que plataforma
4. **Archivos afectados**: Todos los archivos modificados en la solucion
5. **Tags relevantes**: Facilitan busquedas futuras

### Al Marcar Soluciones Fallidas

1. **Razon clara**: Por que exactamente no funciono
2. **Efectos secundarios**: Que otros problemas causo
3. **Condiciones**: Bajo que circunstancias fallo

### Al Generar Tests

1. **Completar TODOs**: El test generado es un template
2. **Agregar mocks**: Configurar dependencias necesarias
3. **Casos limite**: Agregar casos que cubran anti-patrones
4. **Ejecutar test**: Verificar que pasa antes de commit

## Ejemplos

### Ejemplo 1: Error de RLS

```bash
# 1. Error detectado: "infinite recursion detected in policy"

# 2. Buscar similares
python .error-tracker/scripts/search_errors.py "infinite recursion policy"
# Resultado: No encontrado (error nuevo)

# 3. Implementar solucion
# ... modificar codigo ...

# 4. Documentar
python .error-tracker/scripts/add_error.py
# Titulo: RLS Recursion en family_members
# Severidad: high
# Tags: supabase, rls, database

# 5. Generar test
python .error-tracker/scripts/generate_test.py ERR-0001
# Generado: test/regression/integration/err_0001_regression_test.dart
```

### Ejemplo 2: Solucion que Falla

```bash
# La solucion de ERR-0001 causo efectos secundarios

# 1. Marcar como fallida
python .error-tracker/scripts/mark_failed.py ERR-0001 "Causa timeout en sync"

# 2. Buscar nueva aproximacion (revisar anti-patrones)
cat .error-tracker/errors/ERR-0001.json | jq '.anti_patterns'

# 3. Implementar nueva solucion
# ... evitando los anti-patrones ...

# 4. Actualizar documentacion
python .error-tracker/scripts/add_error.py --update ERR-0001
```

### Ejemplo 3: Deteccion de Recurrencia

```bash
# Error aparece en logs
python .error-tracker/scripts/detect_recurrence.py "RLS policy for family_members"

# Resultado:
# ✅ ERR-0001: RLS Recursion en family_members
#    Coincidencia: 85%
#    Estado: resolved
#    
#    SOLUCION CONOCIDA:
#      Usar funcion helper con SECURITY DEFINER materializado
#    
#    NO HACER:
#      - Usar SECURITY DEFINER sin materializar vista
```

---

## Integracion con Claude Code

El skill `error-tracker` se activa automaticamente cuando mencionas:
- "error", "bug", "fix"
- "solucion", "corregir"
- "falla", "no funciona"
- "reaparece"

Claude entonces:
1. Busca errores similares antes de sugerir soluciones
2. Revisa anti-patrones para evitar soluciones fallidas
3. Documenta el error corregido
4. Genera test de regresion

---

**Version**: 1.0.0
**Ultima actualizacion**: 2026-01-05
