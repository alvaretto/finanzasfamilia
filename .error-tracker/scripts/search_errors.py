#!/usr/bin/env python3
"""
Buscar errores similares en el sistema de tracking.
Uso: python search_errors.py "texto a buscar" [--tag TAG] [--file ARCHIVO]
"""

import json
import re
import sys
from pathlib import Path
from typing import List, Tuple

TRACKER_DIR = Path(__file__).parent.parent
ERRORS_DIR = TRACKER_DIR / "errors"
ANTI_PATTERNS_FILE = TRACKER_DIR / "anti-patterns.json"


def load_all_errors() -> List[dict]:
    """Cargar todos los errores."""
    errors = []
    if ERRORS_DIR.exists():
        for f in ERRORS_DIR.glob("ERR-*.json"):
            with open(f, 'r', encoding='utf-8') as file:
                errors.append(json.load(file))
    return errors


def load_anti_patterns() -> dict:
    """Cargar anti-patrones globales."""
    if ANTI_PATTERNS_FILE.exists():
        with open(ANTI_PATTERNS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def calculate_similarity(query: str, error: dict) -> float:
    """Calcular similitud entre query y error (0-1)."""
    query_lower = query.lower()
    query_words = set(query_lower.split())
    
    score = 0.0
    max_score = 0.0
    
    # Título (peso alto)
    title = error.get("title", "").lower()
    title_matches = len(query_words & set(title.split()))
    score += title_matches * 3
    max_score += len(query_words) * 3
    
    # Mensaje de error (peso muy alto)
    error_msg = error.get("error_details", {}).get("message", "").lower()
    if query_lower in error_msg:
        score += 5
    msg_matches = len(query_words & set(error_msg.split()))
    score += msg_matches * 2
    max_score += len(query_words) * 2 + 5
    
    # Keywords de detección (peso alto)
    keywords = [k.lower() for k in error.get("detection_patterns", {}).get("keywords", [])]
    keyword_matches = len(query_words & set(keywords))
    score += keyword_matches * 4
    max_score += len(query_words) * 4
    
    # Descripción (peso medio)
    desc = error.get("description", "").lower()
    desc_matches = len(query_words & set(desc.split()))
    score += desc_matches * 1
    max_score += len(query_words) * 1
    
    # Tags (peso bajo)
    tags = [t.lower() for t in error.get("metadata", {}).get("tags", [])]
    tag_matches = len(query_words & set(tags))
    score += tag_matches * 1.5
    max_score += len(query_words) * 1.5
    
    return score / max_score if max_score > 0 else 0


def search_by_text(query: str, errors: List[dict]) -> List[Tuple[dict, float]]:
    """Buscar por texto libre."""
    results = []
    for error in errors:
        similarity = calculate_similarity(query, error)
        if similarity > 0.1:  # Umbral mínimo
            results.append((error, similarity))
    
    return sorted(results, key=lambda x: x[1], reverse=True)


def search_by_tag(tag: str, errors: List[dict]) -> List[dict]:
    """Buscar por tag específico."""
    tag_lower = tag.lower()
    return [e for e in errors if tag_lower in [t.lower() for t in e.get("metadata", {}).get("tags", [])]]


def search_by_file(filepath: str, errors: List[dict]) -> List[dict]:
    """Buscar por archivo afectado."""
    results = []
    for error in errors:
        affected = error.get("context", {}).get("affected_files", [])
        for f in affected:
            if filepath in f.get("path", ""):
                results.append(error)
                break
    return results


def print_error_summary(error: dict, similarity: float = None):
    """Imprimir resumen de error."""
    status_icons = {
        "open": "🟡",
        "investigating": "🔍",
        "resolved": "✅",
        "reopened": "🔴"
    }
    
    status = error.get("status", "open")
    icon = status_icons.get(status, "⚪")
    
    print(f"\n{icon} {error['id']}: {error['title']}")
    if similarity:
        print(f"   Similitud: {similarity:.0%}")
    print(f"   Severidad: {error.get('severity', 'medium')} | Estado: {status}")
    print(f"   Tags: {', '.join(error.get('metadata', {}).get('tags', []))}")
    
    # Mensaje de error
    msg = error.get("error_details", {}).get("message", "")
    if msg:
        print(f"   Error: {msg[:100]}{'...' if len(msg) > 100 else ''}")
    
    # Archivos afectados
    files = error.get("context", {}).get("affected_files", [])
    if files:
        print(f"   Archivos: {', '.join(f['path'] for f in files[:3])}")
    
    # Solución si existe
    solution = error.get("solution")
    if solution:
        print(f"   ✅ Solución: {solution.get('summary', '')[:80]}")
    
    # Anti-patrones
    anti = error.get("anti_patterns", [])
    if anti:
        print(f"   ⚠️  Anti-patrones ({len(anti)}): {anti[0].get('attempted_solution', '')[:60]}...")


def main():
    if len(sys.argv) < 2:
        print("Uso: python search_errors.py \"texto\" [--tag TAG] [--file ARCHIVO]")
        sys.exit(1)
    
    errors = load_all_errors()
    if not errors:
        print("No hay errores documentados aún.")
        sys.exit(0)
    
    query = sys.argv[1]
    results = []
    
    # Parsear argumentos opcionales
    tag_filter = None
    file_filter = None
    
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--tag" and i + 1 < len(sys.argv):
            tag_filter = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--file" and i + 1 < len(sys.argv):
            file_filter = sys.argv[i + 1]
            i += 2
        else:
            i += 1
    
    # Aplicar filtros
    if tag_filter:
        errors = search_by_tag(tag_filter, errors)
    
    if file_filter:
        errors = search_by_file(file_filter, errors)
    
    # Buscar por texto
    results = search_by_text(query, errors)
    
    if not results:
        print(f"No se encontraron errores similares a: \"{query}\"")
        sys.exit(0)
    
    print(f"\n🔍 Resultados para: \"{query}\"")
    print(f"   Encontrados: {len(results)} errores similares")
    print("=" * 60)
    
    # Mostrar top 5
    for error, similarity in results[:5]:
        print_error_summary(error, similarity)
    
    if len(results) > 5:
        print(f"\n... y {len(results) - 5} más. Usa filtros para refinar.")
    
    # Sugerencia si hay errores resueltos similares
    resolved = [e for e, _ in results if e.get("status") == "resolved"]
    if resolved:
        print(f"\n💡 Hay {len(resolved)} errores similares ya resueltos.")
        print("   Revisa sus soluciones antes de implementar una nueva.")


if __name__ == "__main__":
    main()
