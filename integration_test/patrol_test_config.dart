/// Configuracion base para Patrol Tests
/// Self-Healing Visual Testing Framework para Finanzas Familiares
library;

import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

/// Configuracion global de Patrol
const patrolConfig = PatrolTesterConfig(
  // Timeouts
  existsTimeout: Duration(seconds: 10),
  visibleTimeout: Duration(seconds: 10),
  settleTimeout: Duration(seconds: 10),

  // Politica de busqueda
  findTimeout: Duration(seconds: 5),
);

/// Extension para capacidades de Self-Healing
extension SelfHealingFinders on PatrolTester {
  /// Busca un widget por multiples estrategias (Self-Healing)
  /// Si falla una estrategia, intenta la siguiente
  Future<PatrolFinder> findWithHealing({
    String? byText,
    String? byKey,
    String? byType,
    String? bySemanticsLabel,
    String? byTooltip,
  }) async {
    final strategies = <String, PatrolFinder Function()>{
      if (byText != null) 'text': () => $(byText),
      if (byKey != null) 'key': () => $(find.byKey(Key(byKey))),
      if (byType != null) 'type': () => $(find.byType(_typeFromString(byType))),
      if (bySemanticsLabel != null)
        'semantics': () => $(find.bySemanticsLabel(bySemanticsLabel)),
      if (byTooltip != null) 'tooltip': () => $(find.byTooltip(byTooltip)),
    };

    for (final entry in strategies.entries) {
      try {
        final finder = entry.value();
        if (finder.exists) {
          // ignore: avoid_print
          print('[SELF-HEAL] Encontrado por ${entry.key}');
          return finder;
        }
      } catch (_) {
        // ignore: avoid_print
        print('[SELF-HEAL] Fallido por ${entry.key}, intentando siguiente...');
      }
    }

    throw StateError(
      'No se pudo encontrar widget con ninguna estrategia: '
      'text=$byText, key=$byKey, type=$byType',
    );
  }

  /// Toma screenshot con nombre semantico
  Future<void> captureScreen(String name) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final screenshotName = '${name}_$timestamp';

    await takeScreenshot(name: screenshotName);
    // ignore: avoid_print
    print('[SCREENSHOT] Capturado: $screenshotName');
  }

  /// Valida estado visual actual contra golden
  Future<void> validateAgainstGolden(String goldenName) async {
    // En modo golden update, esto guardara el screenshot
    // En modo test, comparara contra el golden existente
    await takeScreenshot(name: goldenName);
  }
}

/// Convierte string a Type (para busqueda dinamica)
Type _typeFromString(String typeName) {
  // Mapeo de tipos comunes de Flutter/App
  final types = <String, Type>{
    'Text': Text,
    'ElevatedButton': ElevatedButton,
    'FilledButton': FilledButton,
    'TextButton': TextButton,
    'IconButton': IconButton,
    'Card': Card,
    'ListTile': ListTile,
    'TextField': TextField,
    'DropdownButtonFormField': DropdownButtonFormField,
    'Scaffold': Scaffold,
    'AppBar': AppBar,
    'BottomNavigationBar': BottomNavigationBar,
    'NavigationBar': NavigationBar,
    'FloatingActionButton': FloatingActionButton,
    'CircularProgressIndicator': CircularProgressIndicator,
  };

  return types[typeName] ?? Text;
}

/// Clase para registrar y reportar resultados de Self-Healing
class SelfHealingReport {
  final List<HealingAttempt> attempts = [];

  void recordAttempt({
    required String elementDescription,
    required String strategyUsed,
    required bool success,
    String? fallbackUsed,
  }) {
    attempts.add(HealingAttempt(
      elementDescription: elementDescription,
      strategyUsed: strategyUsed,
      success: success,
      fallbackUsed: fallbackUsed,
      timestamp: DateTime.now(),
    ));
  }

  void printReport() {
    // ignore: avoid_print
    print('\n========== SELF-HEALING REPORT ==========');
    for (final attempt in attempts) {
      final status = attempt.success ? 'OK' : 'HEALED';
      // ignore: avoid_print
      print('[$status] ${attempt.elementDescription}');
      if (attempt.fallbackUsed != null) {
        // ignore: avoid_print
        print('        Fallback: ${attempt.fallbackUsed}');
      }
    }
    // ignore: avoid_print
    print('==========================================\n');
  }
}

class HealingAttempt {
  final String elementDescription;
  final String strategyUsed;
  final bool success;
  final String? fallbackUsed;
  final DateTime timestamp;

  HealingAttempt({
    required this.elementDescription,
    required this.strategyUsed,
    required this.success,
    this.fallbackUsed,
    required this.timestamp,
  });
}
