#!/usr/bin/env python3
"""
Marcar una solución como fallida y reabrir el error.
Esto mueve la solución a anti-patterns y permite documentar una nueva.
Uso: python mark_failed.py ERR-XXXX
"""

import json
import sys
from datetime import datetime
from pathlib import Path

TRACKER_DIR = Path(__file__).parent.parent
ERRORS_DIR = TRACKER_DIR / "errors"
ANTI_PATTERNS_FILE = TRACKER_DIR / "anti-patterns.json"
INDEX_FILE = TRACKER_DIR / "index.md"


def load_anti_patterns() -> dict:
    """Cargar anti-patrones globales."""
    if ANTI_PATTERNS_FILE.exists():
        with open(ANTI_PATTERNS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"patterns": [], "by_tag": {}, "by_error_type": {}}


def save_anti_patterns(patterns: dict):
    """Guardar anti-patrones."""
    with open(ANTI_PATTERNS_FILE, 'w', encoding='utf-8') as f:
        json.dump(patterns, f, indent=2, ensure_ascii=False)


def mark_failed(error_id: str, reason: str = None):
    """Marcar solución como fallida."""
    filepath = ERRORS_DIR / f"{error_id}.json"
    
    if not filepath.exists():
        print(f"❌ Error {error_id} no encontrado")
        sys.exit(1)
    
    with open(filepath, 'r', encoding='utf-8') as f:
        error = json.load(f)
    
    solution = error.get("solution")
    if not solution:
        print(f"⚠️  {error_id} no tiene solución documentada")
        sys.exit(1)
    
    if error.get("status") != "resolved":
        print(f"⚠️  {error_id} no está en estado 'resolved'")
        print(f"   Estado actual: {error.get('status')}")
        sys.exit(1)
    
    now = datetime.utcnow().isoformat() + "Z"
    
    # Crear anti-pattern del error
    anti_pattern = {
        "attempted_solution": solution.get("summary", ""),
        "code_changes": solution.get("changes", []),
        "why_failed": reason or "La solución no resolvió el problema definitivamente",
        "side_effects": "",
        "attempted_at": solution.get("applied_at"),
        "failed_at": now
    }
    
    # Agregar al error
    if "anti_patterns" not in error:
        error["anti_patterns"] = []
    error["anti_patterns"].append(anti_pattern)
    
    # Limpiar solución
    error["solution"] = None
    error["status"] = "reopened"
    error["metadata"]["reopened_count"] = error["metadata"].get("reopened_count", 0) + 1
    error["metadata"]["updated_at"] = now
    error["metadata"]["resolved_at"] = None
    
    # Guardar error actualizado
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(error, f, indent=2, ensure_ascii=False)
    
    # Agregar a anti-patrones globales
    global_patterns = load_anti_patterns()
    
    global_anti = {
        "error_id": error_id,
        "error_title": error.get("title"),
        "error_type": error.get("error_details", {}).get("error_type"),
        "tags": error.get("metadata", {}).get("tags", []),
        "attempted_solution": anti_pattern["attempted_solution"],
        "why_failed": anti_pattern["why_failed"],
        "added_at": now
    }
    
    global_patterns["patterns"].append(global_anti)
    
    # Indexar por tags
    for tag in error.get("metadata", {}).get("tags", []):
        if tag not in global_patterns["by_tag"]:
            global_patterns["by_tag"][tag] = []
        global_patterns["by_tag"][tag].append(error_id)
    
    # Indexar por tipo de error
    error_type = error.get("error_details", {}).get("error_type", "unknown")
    if error_type not in global_patterns["by_error_type"]:
        global_patterns["by_error_type"][error_type] = []
    global_patterns["by_error_type"][error_type].append(error_id)
    
    save_anti_patterns(global_patterns)
    
    # Regenerar índice
    rebuild_index()
    
    print(f"\n🔴 {error_id} reabierto")
    print(f"   Solución anterior movida a anti-patterns")
    print(f"   Veces reabierto: {error['metadata']['reopened_count']}")
    print(f"\n⚠️  NO HACER:")
    print(f"   {anti_pattern['attempted_solution']}")
    print(f"\nPróximos pasos:")
    print(f"   1. Buscar otra solución")
    print(f"   2. python add_error.py --update {error_id}")


def rebuild_index():
    """Regenerar índice (versión simplificada)."""
    errors = []
    for f in sorted(ERRORS_DIR.glob("ERR-*.json")):
        with open(f, 'r', encoding='utf-8') as file:
            errors.append(json.load(file))
    
    by_status = {"open": [], "investigating": [], "reopened": [], "resolved": []}
    for e in errors:
        status = e.get("status", "open")
        if status in by_status:
            by_status[status].append(e)
    
    lines = [
        "# Índice de Errores",
        "",
        f"**Total**: {len(errors)} errores",
        f"**Abiertos**: {len(by_status['open']) + len(by_status['investigating']) + len(by_status['reopened'])}",
        f"**Resueltos**: {len(by_status['resolved'])}",
        ""
    ]
    
    if by_status["reopened"]:
        lines.extend(["## 🔴 Reabiertos (Prioridad Alta)", ""])
        for e in by_status["reopened"]:
            anti_count = len(e.get("anti_patterns", []))
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']} ({anti_count} intentos fallidos)")
        lines.append("")
    
    if by_status["open"] or by_status["investigating"]:
        lines.extend(["## 🟡 Abiertos", ""])
        for e in by_status["open"] + by_status["investigating"]:
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']}")
        lines.append("")
    
    if by_status["resolved"]:
        lines.extend(["## ✅ Resueltos", ""])
        for e in by_status["resolved"]:
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']}")
    
    with open(INDEX_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines))


def main():
    if len(sys.argv) < 2:
        print("Uso: python mark_failed.py ERR-XXXX [razón]")
        sys.exit(1)
    
    error_id = sys.argv[1]
    reason = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else None
    
    if not reason:
        reason = input("¿Por qué falló la solución?: ").strip()
    
    mark_failed(error_id, reason)


if __name__ == "__main__":
    main()
