#!/usr/bin/env python3
"""
Detectar si un mensaje de error corresponde a un error previamente documentado.
Uso: python detect_recurrence.py "mensaje de error"
     python detect_recurrence.py --file path/to/error.log
"""

import json
import re
import sys
from pathlib import Path
from typing import List, Tuple, Optional

TRACKER_DIR = Path(__file__).parent.parent
ERRORS_DIR = TRACKER_DIR / "errors"
PATTERNS_FILE = TRACKER_DIR / "patterns.json"
ANTI_PATTERNS_FILE = TRACKER_DIR / "anti-patterns.json"


def load_patterns() -> dict:
    """Cargar patrones de detección."""
    if PATTERNS_FILE.exists():
        with open(PATTERNS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"errors": {}}


def load_anti_patterns() -> dict:
    """Cargar anti-patrones."""
    if ANTI_PATTERNS_FILE.exists():
        with open(ANTI_PATTERNS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"patterns": []}


def load_error(error_id: str) -> Optional[dict]:
    """Cargar error por ID."""
    filepath = ERRORS_DIR / f"{error_id}.json"
    if filepath.exists():
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    return None


def extract_keywords(text: str) -> set:
    """Extraer palabras clave de un texto."""
    text = text.lower()
    text = re.sub(r'[^\w\s\-_]', ' ', text)
    words = set(text.split())
    stopwords = {'the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'is', 'was', 'are', 'were',
                 'el', 'la', 'los', 'las', 'un', 'una', 'en', 'de', 'que', 'y', 'o', 'es', 'son', 'fue', 'ser'}
    return {w for w in words if len(w) > 2 and w not in stopwords}


def match_regex(error_msg: str, pattern_regex: str) -> bool:
    """Verificar si mensaje coincide con regex."""
    if not pattern_regex:
        return False
    try:
        return bool(re.search(pattern_regex, error_msg, re.IGNORECASE))
    except re.error:
        return False


def calculate_match_score(error_msg: str, pattern: dict) -> float:
    """Calcular score de coincidencia (0-1)."""
    score = 0.0
    max_score = 0.0
    
    msg_keywords = extract_keywords(error_msg)
    
    if pattern.get("error_regex"):
        max_score += 5
        if match_regex(error_msg, pattern["error_regex"]):
            score += 5
    
    pattern_keywords = set(k.lower() for k in pattern.get("keywords", []))
    if pattern_keywords:
        max_score += 4
        keyword_overlap = len(msg_keywords & pattern_keywords)
        if keyword_overlap > 0:
            score += min(4, keyword_overlap * 1.5)
    
    tags = set(t.lower() for t in pattern.get("tags", []))
    if tags:
        max_score += 1
        tag_overlap = len(msg_keywords & tags)
        score += min(1, tag_overlap * 0.5)
    
    return score / max_score if max_score > 0 else 0


def find_matching_errors(error_msg: str) -> List[Tuple[str, float, dict]]:
    """Encontrar errores que coincidan con el mensaje."""
    patterns = load_patterns()
    matches = []
    
    for error_id, pattern in patterns.get("errors", {}).items():
        score = calculate_match_score(error_msg, pattern)
        if score > 0.2:
            error_data = load_error(error_id)
            if error_data:
                matches.append((error_id, score, error_data))
    
    return sorted(matches, key=lambda x: x[1], reverse=True)


def get_anti_patterns_for_error(error_id: str) -> List[dict]:
    """Obtener anti-patrones específicos de un error."""
    error = load_error(error_id)
    if error:
        return error.get("anti_patterns", [])
    return []


def get_global_anti_patterns(tags: List[str]) -> List[dict]:
    """Obtener anti-patrones globales relevantes por tags."""
    anti_patterns = load_anti_patterns()
    relevant = []
    
    for ap in anti_patterns.get("patterns", []):
        ap_tags = set(ap.get("tags", []))
        if ap_tags & set(tags):
            relevant.append(ap)
    
    return relevant


def print_match(error_id: str, score: float, error: dict):
    """Imprimir coincidencia encontrada."""
    status_icons = {
        "open": "🟡",
        "investigating": "🔍",
        "resolved": "✅",
        "reopened": "🔴"
    }
    
    status = error.get("status", "open")
    icon = status_icons.get(status, "⚪")
    
    print(f"\n{icon} {error_id}: {error.get('title')}")
    print(f"   Coincidencia: {score:.0%}")
    print(f"   Estado: {status} | Severidad: {error.get('severity')}")
    
    msg = error.get("error_details", {}).get("message", "")
    if msg:
        print(f"   Error original: {msg[:80]}...")
    
    solution = error.get("solution")
    if solution:
        print(f"\n   ✅ SOLUCIÓN CONOCIDA:")
        print(f"      {solution.get('summary', 'Ver JSON para detalles')}")
        print(f"      Causa raíz: {solution.get('root_cause', 'N/A')}")
    
    anti = error.get("anti_patterns", [])
    if anti:
        print(f"\n   ⚠️  NO HACER ({len(anti)} intentos fallidos):")
        for ap in anti[:2]:
            print(f"      ❌ {ap.get('attempted_solution', 'N/A')[:60]}")
            print(f"         Razón: {ap.get('why_failed', 'N/A')[:50]}")


def main():
    if len(sys.argv) < 2:
        print("Uso: python detect_recurrence.py \"mensaje de error\"")
        print("     python detect_recurrence.py --file path/to/error.log")
        sys.exit(1)
    
    if sys.argv[1] == "--file":
        if len(sys.argv) < 3:
            print("Especifica el archivo de log")
            sys.exit(1)
        with open(sys.argv[2], 'r') as f:
            error_msg = f.read()
    else:
        error_msg = " ".join(sys.argv[1:])
    
    print(f"\n🔍 Buscando errores similares...")
    print(f"   Mensaje: {error_msg[:100]}{'...' if len(error_msg) > 100 else ''}")
    print("=" * 60)
    
    matches = find_matching_errors(error_msg)
    
    if not matches:
        print("\n✨ No se encontraron errores similares documentados.")
        print("   Este parece ser un error nuevo.")
        print(f"\n   Para documentarlo:")
        print(f"   python {TRACKER_DIR}/scripts/add_error.py")
        sys.exit(0)
    
    print(f"\n⚠️  Encontrados {len(matches)} errores similares:")
    
    for error_id, score, error in matches[:3]:
        print_match(error_id, score, error)
    
    if len(matches) > 3:
        print(f"\n... y {len(matches) - 3} más.")
    
    best_match = matches[0]
    if best_match[1] > 0.6:
        error = best_match[2]
        print("\n" + "=" * 60)
        print("📋 RECOMENDACIÓN:")
        
        if error.get("status") == "resolved":
            print(f"   Este error ({best_match[0]}) ya fue resuelto.")
            print(f"   Revisa si la solución sigue aplicando.")
            solution = error.get("solution", {})
            if solution.get("changes"):
                print(f"   Archivos modificados:")
                for change in solution["changes"][:3]:
                    print(f"      - {change.get('file', 'N/A')}")
        
        elif error.get("status") == "reopened":
            print(f"   ⚠️  Este error ({best_match[0]}) ha sido reabierto {error['metadata'].get('reopened_count', 1)} veces.")
            print(f"   Las soluciones anteriores NO funcionaron.")
            print(f"   Revisa los anti-patrones antes de intentar algo nuevo.")
        
        else:
            print(f"   Este error ({best_match[0]}) está siendo investigado.")
            print(f"   Considera contribuir a la solución.")


if __name__ == "__main__":
    main()
