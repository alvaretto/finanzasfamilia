#!/usr/bin/env python3
"""
Script para eliminar líneas vacías antes de TODOS los ítems de lista.
Esto restaura los archivos al estado original antes del formato.
"""
import re
from pathlib import Path

def clean_markdown_lists(file_path):
    """Elimina todas las líneas vacías inmediatamente antes de ítems de lista."""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    cleaned_lines = []
    i = 0

    while i < len(lines):
        current_line = lines[i]

        # Verificar si la línea siguiente es un ítem de lista
        is_next_list_item = False
        if i + 1 < len(lines):
            next_line = lines[i + 1]
            is_next_list_item = (
                re.match(r'^\s*[-*+]\s+', next_line) or
                re.match(r'^\s*\d+\.\s+', next_line)
            )

        # Si la línea actual está vacía Y la siguiente es ítem de lista, omitir esta línea vacía
        if current_line.strip() == '' and is_next_list_item:
            i += 1
            continue

        cleaned_lines.append(current_line)
        i += 1

    # Escribir resultado
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(cleaned_lines)

    return len(lines) - len(cleaned_lines)

if __name__ == '__main__':
    files = [
        'docs/files/NORMATIVIDAD_CONTABLE_COLOMBIA_2025.md',
        'docs/files/GUIA_MODO_PERSONAL.md',
        'docs/files/NORMATIVIDAD_RESUMEN_EJECUTIVO.md',
    ]

    total_removed = 0
    for file_path in files:
        full_path = Path(file_path)
        if full_path.exists():
            removed = clean_markdown_lists(full_path)
            total_removed += removed
            print(f'✓ {file_path}: {removed} líneas vacías eliminadas')
        else:
            print(f'✗ {file_path}: No encontrado')

    print(f'\nTotal: {total_removed} líneas vacías eliminadas')
