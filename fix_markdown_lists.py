#!/usr/bin/env python3
"""
Script para agregar línea vacía antes de listados en archivos Markdown.
"""
import re
from pathlib import Path

def fix_markdown_lists(file_path):
    """Agrega línea vacía antes de listados si no la hay."""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    fixed_lines = []
    prev_line_empty = True  # Consideramos que antes del inicio hay línea vacía
    prev_was_list_item = False  # Rastrear si la línea anterior era ítem de lista

    for i, line in enumerate(lines):
        # Detectar si la línea actual es inicio de lista
        is_list_item = (
            re.match(r'^\s*[-*+]\s+', line) or  # Viñetas: -, *, +
            re.match(r'^\s*\d+\.\s+', line)      # Numeradas: 1., 2., etc.
        )

        # Solo agregar línea vacía si:
        # - La línea actual ES un ítem de lista
        # - La línea anterior NO era un ítem de lista (inicio de nuevo listado)
        # - La línea anterior NO está vacía
        if is_list_item and not prev_was_list_item and not prev_line_empty:
            fixed_lines.append('\n')

        fixed_lines.append(line)

        # Actualizar estado para siguiente iteración
        prev_line_empty = line.strip() == ''
        prev_was_list_item = is_list_item

    # Escribir resultado
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(fixed_lines)

    return len([l for l in lines if re.match(r'^\s*[-*+\d]\s+', l)])

if __name__ == '__main__':
    files = [
        'docs/files/NORMATIVIDAD_CONTABLE_COLOMBIA_2025.md',
        'docs/files/GUIA_MODO_PERSONAL.md',
        'docs/files/NORMATIVIDAD_RESUMEN_EJECUTIVO.md',
    ]

    for file_path in files:
        full_path = Path(file_path)
        if full_path.exists():
            total_lists = fix_markdown_lists(full_path)
            print(f'✓ {file_path}: {total_lists} listados procesados')
        else:
            print(f'✗ {file_path}: No encontrado')
