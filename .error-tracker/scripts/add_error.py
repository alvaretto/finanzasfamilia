#!/usr/bin/env python3
"""
Agregar o actualizar errores en el sistema de tracking.
Uso: python add_error.py [--update ERR-XXXX]
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

TRACKER_DIR = Path(__file__).parent.parent
ERRORS_DIR = TRACKER_DIR / "errors"
INDEX_FILE = TRACKER_DIR / "index.md"
PATTERNS_FILE = TRACKER_DIR / "patterns.json"


def get_next_id() -> str:
    """Obtener siguiente ID disponible."""
    ERRORS_DIR.mkdir(parents=True, exist_ok=True)
    existing = list(ERRORS_DIR.glob("ERR-*.json"))
    if not existing:
        return "ERR-0001"
    
    max_num = max(int(f.stem.split("-")[1]) for f in existing)
    return f"ERR-{max_num + 1:04d}"


def create_error_template(error_id: str) -> dict:
    """Crear plantilla de error vacía."""
    now = datetime.utcnow().isoformat() + "Z"
    return {
        "id": error_id,
        "title": "",
        "description": "",
        "severity": "medium",
        "status": "open",
        "error_details": {
            "message": "",
            "stack_trace": "",
            "error_type": "runtime",
            "reproducibility": "always"
        },
        "context": {
            "affected_files": [],
            "environment": {
                "flutter_version": "",
                "platform": "",
                "mode": "debug"
            },
            "user_action": "",
            "prerequisites": ""
        },
        "solution": None,
        "anti_patterns": [],
        "related_tests": [],
        "metadata": {
            "created_at": now,
            "updated_at": now,
            "resolved_at": None,
            "reopened_count": 0,
            "tags": [],
            "related_errors": [],
            "references": []
        },
        "detection_patterns": {
            "error_regex": "",
            "keywords": [],
            "file_patterns": []
        }
    }


def add_solution(error: dict, solution_data: dict) -> dict:
    """Agregar solución a un error."""
    now = datetime.utcnow().isoformat() + "Z"
    error["solution"] = {
        "summary": solution_data.get("summary", ""),
        "changes": solution_data.get("changes", []),
        "root_cause": solution_data.get("root_cause", ""),
        "applied_at": now,
        "verified": False
    }
    error["status"] = "resolved"
    error["metadata"]["resolved_at"] = now
    error["metadata"]["updated_at"] = now
    return error


def save_error(error: dict) -> Path:
    """Guardar error a archivo JSON."""
    ERRORS_DIR.mkdir(parents=True, exist_ok=True)
    filepath = ERRORS_DIR / f"{error['id']}.json"
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(error, f, indent=2, ensure_ascii=False)
    return filepath


def update_patterns(error: dict):
    """Actualizar archivo de patrones para detección."""
    patterns = {}
    if PATTERNS_FILE.exists():
        with open(PATTERNS_FILE, 'r', encoding='utf-8') as f:
            patterns = json.load(f)
    
    if "errors" not in patterns:
        patterns["errors"] = {}
    
    patterns["errors"][error["id"]] = {
        "keywords": error["detection_patterns"]["keywords"],
        "error_regex": error["detection_patterns"]["error_regex"],
        "file_patterns": error["detection_patterns"]["file_patterns"],
        "tags": error["metadata"]["tags"]
    }
    
    with open(PATTERNS_FILE, 'w', encoding='utf-8') as f:
        json.dump(patterns, f, indent=2, ensure_ascii=False)


def rebuild_index():
    """Regenerar el índice Markdown."""
    errors = []
    for f in sorted(ERRORS_DIR.glob("ERR-*.json")):
        with open(f, 'r', encoding='utf-8') as file:
            errors.append(json.load(file))
    
    # Agrupar por estado
    by_status = {"open": [], "investigating": [], "reopened": [], "resolved": []}
    for e in errors:
        status = e.get("status", "open")
        if status in by_status:
            by_status[status].append(e)
    
    lines = [
        "# Índice de Errores",
        "",
        f"**Total**: {len(errors)} errores documentados",
        f"**Abiertos**: {len(by_status['open']) + len(by_status['investigating']) + len(by_status['reopened'])}",
        f"**Resueltos**: {len(by_status['resolved'])}",
        "",
        "---",
        ""
    ]
    
    # Errores activos primero
    if by_status["reopened"]:
        lines.extend(["## 🔴 Reabiertos", ""])
        for e in by_status["reopened"]:
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']} ({e['severity']})")
        lines.append("")
    
    if by_status["open"] or by_status["investigating"]:
        lines.extend(["## 🟡 Abiertos", ""])
        for e in by_status["open"] + by_status["investigating"]:
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']} ({e['severity']})")
        lines.append("")
    
    if by_status["resolved"]:
        lines.extend(["## ✅ Resueltos", ""])
        for e in by_status["resolved"]:
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']}")
        lines.append("")
    
    # Por tags
    all_tags = set()
    for e in errors:
        all_tags.update(e["metadata"].get("tags", []))
    
    if all_tags:
        lines.extend(["---", "", "## Por Tags", ""])
        for tag in sorted(all_tags):
            tagged = [e for e in errors if tag in e["metadata"].get("tags", [])]
            lines.append(f"- `{tag}`: {len(tagged)} errores")
    
    with open(INDEX_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines))


def interactive_add():
    """Modo interactivo para agregar error."""
    error_id = get_next_id()
    error = create_error_template(error_id)
    
    print(f"\n📝 Nuevo Error: {error_id}")
    print("-" * 40)
    
    error["title"] = input("Título (breve): ").strip()
    error["description"] = input("Descripción (detallada): ").strip()
    error["severity"] = input("Severidad [critical/high/medium/low] (medium): ").strip() or "medium"
    error["error_details"]["message"] = input("Mensaje de error exacto: ").strip()
    
    files_input = input("Archivos afectados (separados por coma): ").strip()
    if files_input:
        error["context"]["affected_files"] = [
            {"path": f.strip(), "lines": [], "function": ""} 
            for f in files_input.split(",")
        ]
    
    tags_input = input("Tags (separados por coma): ").strip()
    if tags_input:
        error["metadata"]["tags"] = [t.strip() for t in tags_input.split(",")]
    
    keywords_input = input("Palabras clave para detección (separadas por coma): ").strip()
    if keywords_input:
        error["detection_patterns"]["keywords"] = [k.strip() for k in keywords_input.split(",")]
    
    # Guardar
    filepath = save_error(error)
    update_patterns(error)
    rebuild_index()
    
    print(f"\n✅ Error guardado en: {filepath}")
    print(f"   Edita el JSON para agregar más detalles.")
    return error


def update_existing(error_id: str):
    """Actualizar error existente."""
    filepath = ERRORS_DIR / f"{error_id}.json"
    if not filepath.exists():
        print(f"❌ Error {error_id} no encontrado")
        sys.exit(1)
    
    with open(filepath, 'r', encoding='utf-8') as f:
        error = json.load(f)
    
    print(f"\n📝 Actualizando: {error_id}")
    print(f"   Título actual: {error['title']}")
    print(f"   Estado actual: {error['status']}")
    print("-" * 40)
    
    action = input("¿Qué deseas hacer? [solution/reopen/edit]: ").strip().lower()
    
    if action == "solution":
        summary = input("Resumen de la solución: ").strip()
        root_cause = input("Causa raíz: ").strip()
        error = add_solution(error, {"summary": summary, "root_cause": root_cause})
        print("✅ Solución agregada, estado: resolved")
    
    elif action == "reopen":
        error["status"] = "reopened"
        error["metadata"]["reopened_count"] += 1
        error["metadata"]["updated_at"] = datetime.utcnow().isoformat() + "Z"
        print("🔴 Error reabierto")
    
    elif action == "edit":
        print("Edita el archivo JSON directamente:", filepath)
        return
    
    save_error(error)
    update_patterns(error)
    rebuild_index()
    print(f"✅ Actualizado: {filepath}")


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--update":
        if len(sys.argv) < 3:
            print("Uso: python add_error.py --update ERR-XXXX")
            sys.exit(1)
        update_existing(sys.argv[2])
    else:
        interactive_add()


if __name__ == "__main__":
    main()
