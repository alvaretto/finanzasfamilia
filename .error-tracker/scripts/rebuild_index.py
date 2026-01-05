#!/usr/bin/env python3
"""
Reconstruir el índice de errores (index.md).
Uso: python rebuild_index.py
"""

import json
from pathlib import Path
from datetime import datetime

TRACKER_DIR = Path(__file__).parent.parent
ERRORS_DIR = TRACKER_DIR / "errors"
INDEX_FILE = TRACKER_DIR / "index.md"
ANTI_PATTERNS_FILE = TRACKER_DIR / "anti-patterns.json"


def load_all_errors():
    """Cargar todos los errores."""
    errors = []
    if ERRORS_DIR.exists():
        for f in sorted(ERRORS_DIR.glob("ERR-*.json")):
            with open(f, 'r', encoding='utf-8') as file:
                errors.append(json.load(file))
    return errors


def rebuild_index():
    """Reconstruir índice completo."""
    errors = load_all_errors()
    
    by_status = {"open": [], "investigating": [], "reopened": [], "resolved": []}
    by_severity = {"critical": [], "high": [], "medium": [], "low": []}
    by_tag = {}
    
    for e in errors:
        status = e.get("status", "open")
        if status in by_status:
            by_status[status].append(e)
        
        severity = e.get("severity", "medium")
        if severity in by_severity:
            by_severity[severity].append(e)
        
        for tag in e.get("metadata", {}).get("tags", []):
            if tag not in by_tag:
                by_tag[tag] = []
            by_tag[tag].append(e)
    
    total_anti = sum(len(e.get("anti_patterns", [])) for e in errors)
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
    
    lines = [
        "# 📋 Índice de Errores",
        "",
        f"*Última actualización: {now}*",
        "",
        "## Resumen",
        "",
        f"| Métrica | Valor |",
        f"|---------|-------|",
        f"| Total errores | {len(errors)} |",
        f"| Abiertos | {len(by_status['open']) + len(by_status['investigating'])} |",
        f"| Reabiertos | {len(by_status['reopened'])} |",
        f"| Resueltos | {len(by_status['resolved'])} |",
        f"| Anti-patrones documentados | {total_anti} |",
        "",
        "---",
        ""
    ]
    
    if by_status["reopened"]:
        lines.extend([
            "## 🔴 Reabiertos (Prioridad Máxima)",
            "",
            "Estos errores tuvieron soluciones que fallaron. Revisar anti-patrones antes de intentar nuevas soluciones.",
            ""
        ])
        for e in sorted(by_status["reopened"], key=lambda x: x["metadata"].get("reopened_count", 0), reverse=True):
            anti_count = len(e.get("anti_patterns", []))
            reopen_count = e["metadata"].get("reopened_count", 1)
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']}")
            lines.append(f"  - Severidad: {e.get('severity')} | Reabierto {reopen_count}x | {anti_count} anti-patrones")
        lines.append("")
    
    critical_open = [e for e in by_status["open"] + by_status["investigating"] if e.get("severity") == "critical"]
    if critical_open:
        lines.extend([
            "## 🚨 Críticos Abiertos",
            ""
        ])
        for e in critical_open:
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']}")
        lines.append("")
    
    other_open = [e for e in by_status["open"] + by_status["investigating"] if e.get("severity") != "critical"]
    if other_open:
        lines.extend([
            "## 🟡 Abiertos",
            ""
        ])
        severity_order = {"high": 0, "medium": 1, "low": 2}
        other_open.sort(key=lambda x: severity_order.get(x.get("severity", "medium"), 1))
        for e in other_open:
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']} ({e.get('severity')})")
        lines.append("")
    
    if by_status["resolved"]:
        lines.extend([
            "## ✅ Resueltos Recientes",
            ""
        ])
        resolved_sorted = sorted(
            by_status["resolved"],
            key=lambda x: x["metadata"].get("resolved_at", ""),
            reverse=True
        )[:10]
        for e in resolved_sorted:
            resolved_at = e["metadata"].get("resolved_at", "")[:10] if e["metadata"].get("resolved_at") else "N/A"
            lines.append(f"- **[{e['id']}](errors/{e['id']}.json)**: {e['title']} ({resolved_at})")
        
        if len(by_status["resolved"]) > 10:
            lines.append(f"- *... y {len(by_status['resolved']) - 10} más*")
        lines.append("")
    
    if by_tag:
        lines.extend([
            "---",
            "",
            "## 🏷️ Por Tags",
            ""
        ])
        for tag in sorted(by_tag.keys()):
            count = len(by_tag[tag])
            open_count = len([e for e in by_tag[tag] if e.get("status") in ["open", "investigating", "reopened"]])
            lines.append(f"- `{tag}`: {count} errores ({open_count} abiertos)")
        lines.append("")
    
    lines.extend([
        "---",
        "",
        "## 🔧 Comandos Rápidos",
        "",
        "```bash",
        "# Buscar errores similares",
        "python .error-tracker/scripts/search_errors.py \"mensaje\"",
        "",
        "# Detectar si error ya existe",
        "python .error-tracker/scripts/detect_recurrence.py \"mensaje\"",
        "",
        "# Agregar nuevo error",
        "python .error-tracker/scripts/add_error.py",
        "",
        "# Marcar solución como fallida",
        "python .error-tracker/scripts/mark_failed.py ERR-XXXX",
        "",
        "# Generar test de regresión",
        "python .error-tracker/scripts/generate_test.py ERR-XXXX",
        "```"
    ])
    
    with open(INDEX_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines))
    
    print(f"✅ Índice regenerado: {INDEX_FILE}")
    print(f"   Total: {len(errors)} errores")
    print(f"   Abiertos: {len(by_status['open']) + len(by_status['investigating']) + len(by_status['reopened'])}")
    print(f"   Resueltos: {len(by_status['resolved'])}")


if __name__ == "__main__":
    rebuild_index()
