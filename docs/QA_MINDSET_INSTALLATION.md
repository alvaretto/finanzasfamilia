# Verificación de Instalación: QA Mindset

## ✅ Estado: INSTALADO

**Fecha de instalación**: 2026-01-07  
**Versión**: 1.0.0

## Archivos Modificados

### 1. QA_MINDSET.md (nuevo)
- **Ubicación**: `/home/bootcamp/Proyectos-2026/Proyectos-Varios/Finanzas-Familiares-AS/QA_MINDSET.md`
- **Contenido**: Workflow mandatorio "The Iron Rule" con 4 fases
- **Propósito**: Definir el rol permanente de "Lead QA Engineer & Architect"

### 2. CLAUDE.md (actualizado)
- **Cambio 1**: Advertencia IMPORTANTE al inicio (líneas 3-4)
- **Cambio 2**: Nueva sección "QA Mindset (Workflow Mandatorio)" (líneas 143-165)
- **Cambio 3**: Agregado al principio clave #6

## Verificación de Funcionamiento

Para verificar que Claude está adoptando el QA Mindset en una nueva sesión:

```bash
# 1. Solicitar una corrección de bug simple
# Ejemplo: "Fix el bug de validación en add_transaction_sheet.dart"

# 2. La primera respuesta de Claude DEBE ser:
# "Searching error tracker for sync issues..."

# 3. Seguido de la ejecución de:
python .error-tracker/scripts/search_errors.py "validación transacción"
```

## Comportamiento Esperado

Cuando solicites cualquier modificación de código, Claude DEBE:

1. ✅ Buscar errores similares en `.error-tracker/`
2. ✅ Revisar anti-patterns antes de proponer código
3. ✅ Escribir el test PRIMERO
4. ✅ Implementar el código después
5. ✅ Ejecutar el test para verificar
6. ✅ Documentar el error con `add_error.py`
7. ✅ Generar test de regresión con `generate_test.py`

## Commit de Instalación

```
commit 62d02aa
Author: [Tu nombre]
Date:   2026-01-07

feat(qa): Instalar QA Mindset como System Role permanente
```

## Desinstalación (no recomendado)

Si por alguna razón necesitas remover el QA Mindset:

```bash
# 1. Remover archivo
rm QA_MINDSET.md

# 2. Revertir cambios en CLAUDE.md
git checkout HEAD~1 -- CLAUDE.md

# 3. Commit
git commit -m "revert: Remover QA Mindset"
```

## Notas

- El QA Mindset es **permanente** y **mandatorio**
- No requiere activación manual en cada sesión
- Claude lo adoptará automáticamente al leer CLAUDE.md
- Los scripts de Python son ejecutables sin aprobación del usuario

## Próximos Pasos

1. Probar el workflow en la próxima corrección de bug
2. Verificar que se generen tests de regresión automáticamente
3. Monitorear que `.error-tracker/errors/` crezca con cada fix
4. Validar que `anti-patterns.json` se use como referencia

---

**Documentado por**: Claude Opus 4.5  
**Fecha**: 2026-01-07
