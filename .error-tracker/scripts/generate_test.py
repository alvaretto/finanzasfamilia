#!/usr/bin/env python3
"""
Generar tests de regresión a partir de errores documentados.
Uso: python generate_test.py ERR-XXXX [--type unit|integration|widget]
"""

import json
import sys
import os
from datetime import datetime
from pathlib import Path

TRACKER_DIR = Path(__file__).parent.parent
ERRORS_DIR = TRACKER_DIR / "errors"
PROJECT_ROOT = TRACKER_DIR.parent

UNIT_TEST_TEMPLATE = '''import 'package:flutter_test/flutter_test.dart';
{imports}

/// Test de regresión para {error_id}: {title}
/// 
/// Causa raíz: {root_cause}
/// Archivo original: {affected_file}
/// 
/// Este test verifica que el error no reaparezca.
void main() {{
  group('{error_id} Regression', () {{
    {setup}
    
    test('should not exhibit the original error behavior', () {{
      // Arrange
      {arrange}
      
      // Act
      {act}
      
      // Assert
      {assert_code}
    }});
    
    test('should handle edge cases correctly', () {{
      // Casos límite identificados del error original
      {edge_cases}
    }});
  }});
}}
'''

WIDGET_TEST_TEMPLATE = '''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
{imports}

/// Widget test de regresión para {error_id}: {title}
/// 
/// Causa raíz: {root_cause}
/// Widget afectado: {affected_file}
void main() {{
  group('{error_id} Widget Regression', () {{
    testWidgets('should render correctly without the original error', 
        (WidgetTester tester) async {{
      // Arrange
      {arrange}
      
      // Act
      await tester.pumpWidget({widget_setup});
      await tester.pumpAndSettle();
      
      // Assert - No debe mostrar el comportamiento erróneo
      {assert_code}
    }});
    
    testWidgets('should handle user interaction without error',
        (WidgetTester tester) async {{
      {interaction_test}
    }});
  }});
}}
'''

INTEGRATION_TEST_TEMPLATE = '''import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
{imports}

/// Integration test de regresión para {error_id}: {title}
/// 
/// Causa raíz: {root_cause}
/// Flujo afectado: {affected_file}
void main() {{
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('{error_id} Integration Regression', () {{
    {setup}
    
    testWidgets('complete flow should work without the original error',
        (WidgetTester tester) async {{
      // Setup
      {arrange}
      
      // Execute flow
      {flow_steps}
      
      // Verify
      {assert_code}
    }});
  }});
}}
'''


def load_error(error_id: str) -> dict:
    """Cargar error por ID."""
    filepath = ERRORS_DIR / f"{error_id}.json"
    if not filepath.exists():
        print(f"❌ Error {error_id} no encontrado")
        sys.exit(1)
    
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def determine_test_type(error: dict) -> str:
    """Determinar tipo de test basado en el error."""
    error_type = error.get("error_details", {}).get("error_type", "")
    tags = error.get("metadata", {}).get("tags", [])
    affected = error.get("context", {}).get("affected_files", [])
    
    if any(f.get("path", "").endswith("_screen.dart") for f in affected):
        return "widget"
    if any(f.get("path", "").endswith("_page.dart") for f in affected):
        return "widget"
    if "ui" in tags or "widget" in tags:
        return "widget"
    if "e2e" in tags or "flow" in tags:
        return "integration"
    if any(t in tags for t in ["sync", "auth", "database", "network"]):
        return "integration"
    
    return "unit"


def generate_imports(error: dict) -> str:
    """Generar imports necesarios."""
    imports = []
    affected = error.get("context", {}).get("affected_files", [])
    
    for f in affected:
        path = f.get("path", "")
        if path.startswith("lib/"):
            import_path = path.replace("lib/", "package:finanzas_familiares/")
            import_path = import_path.replace(".dart", ".dart")
            imports.append(f"import '{import_path}';")
    
    return "\n".join(imports) if imports else "// TODO: Agregar imports necesarios"


def generate_test_content(error: dict, test_type: str) -> str:
    """Generar contenido del test."""
    template = {
        "unit": UNIT_TEST_TEMPLATE,
        "widget": WIDGET_TEST_TEMPLATE,
        "integration": INTEGRATION_TEST_TEMPLATE
    }.get(test_type, UNIT_TEST_TEMPLATE)
    
    affected_files = error.get("context", {}).get("affected_files", [])
    affected_file = affected_files[0]["path"] if affected_files else "unknown"
    
    solution = error.get("solution", {}) or {}
    anti_patterns = error.get("anti_patterns", [])
    
    setup_code = "// TODO: Configurar mocks y dependencias"
    arrange_code = "// TODO: Preparar datos de prueba"
    act_code = "// TODO: Ejecutar la acción que causaba el error"
    assert_code = "// TODO: Verificar que el error no ocurre"
    
    if solution:
        root_cause = solution.get("root_cause", "No documentada")
        changes = solution.get("changes", [])
        if changes:
            change = changes[0]
            assert_code = f'''// Verificar comportamiento correcto
      // Antes: {change.get('before', 'N/A')[:50]}...
      // Ahora: {change.get('after', 'N/A')[:50]}...
      // TODO: Agregar assertions específicas'''
    else:
        root_cause = "Pendiente de documentar"
    
    edge_cases = ""
    if anti_patterns:
        edge_cases = "// ⚠️ Anti-patrones conocidos - NO hacer:\n"
        for ap in anti_patterns[:3]:
            edge_cases += f"      // - {ap.get('attempted_solution', 'N/A')[:60]}\n"
        edge_cases += "      // TODO: Agregar casos que verifiquen que no caemos en anti-patrones"
    else:
        edge_cases = "// TODO: Agregar casos límite"
    
    return template.format(
        error_id=error["id"],
        title=error.get("title", "Sin título"),
        root_cause=root_cause,
        affected_file=affected_file,
        imports=generate_imports(error),
        setup=setup_code,
        arrange=arrange_code,
        act=act_code,
        assert_code=assert_code,
        edge_cases=edge_cases,
        widget_setup="MaterialApp(home: Scaffold())",
        interaction_test="// TODO: Test de interacción",
        flow_steps="// TODO: Pasos del flujo"
    )


def get_test_path(error: dict, test_type: str) -> Path:
    """Determinar path del archivo de test."""
    error_id = error["id"].lower().replace("-", "_")
    
    affected = error.get("context", {}).get("affected_files", [])
    subdir = ""
    
    if affected:
        path = affected[0].get("path", "")
        if "/features/" in path:
            parts = path.split("/features/")[1].split("/")
            if parts:
                subdir = parts[0]
    
    base_dir = PROJECT_ROOT / "test" / "regression" / test_type
    if subdir:
        base_dir = base_dir / subdir
    
    return base_dir / f"{error_id}_regression_test.dart"


def update_error_with_test(error: dict, test_path: Path):
    """Actualizar error con referencia al test generado."""
    now = datetime.utcnow().isoformat() + "Z"
    
    if "related_tests" not in error:
        error["related_tests"] = []
    
    error["related_tests"].append({
        "path": str(test_path.relative_to(PROJECT_ROOT)) if test_path.is_relative_to(PROJECT_ROOT) else str(test_path),
        "type": test_path.parent.name,
        "generated_at": now
    })
    
    error["metadata"]["updated_at"] = now
    
    filepath = ERRORS_DIR / f"{error['id']}.json"
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(error, f, indent=2, ensure_ascii=False)


def main():
    if len(sys.argv) < 2:
        print("Uso: python generate_test.py ERR-XXXX [--type unit|integration|widget]")
        sys.exit(1)
    
    error_id = sys.argv[1]
    
    test_type = None
    if "--type" in sys.argv:
        idx = sys.argv.index("--type")
        if idx + 1 < len(sys.argv):
            test_type = sys.argv[idx + 1]
    
    error = load_error(error_id)
    
    if not test_type:
        test_type = determine_test_type(error)
        print(f"📋 Tipo de test detectado: {test_type}")
    
    test_content = generate_test_content(error, test_type)
    test_path = get_test_path(error, test_type)
    
    test_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(test_path, 'w', encoding='utf-8') as f:
        f.write(test_content)
    
    update_error_with_test(error, test_path)
    
    print(f"\n✅ Test generado: {test_path}")
    print(f"   Tipo: {test_type}")
    print(f"   Error: {error_id} - {error.get('title')}")
    print(f"\n⚠️  El test tiene TODOs que debes completar:")
    print(f"   - Imports específicos")
    print(f"   - Setup y mocks")
    print(f"   - Assertions concretas")
    print(f"\nPara ejecutar:")
    print(f"   flutter test {test_path}")


if __name__ == "__main__":
    main()
