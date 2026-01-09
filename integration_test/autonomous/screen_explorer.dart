/// Explorador Autonomo de Pantallas
/// Navega automaticamente por la app, captura estados y detecta cambios
library;

import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

/// Configuracion del explorador autonomo
class ExplorerConfig {
  /// Profundidad maxima de navegacion
  final int maxDepth;

  /// Capturar screenshot en cada paso
  final bool screenshotOnEveryStep;

  /// Tiempo maximo de exploracion (minutos)
  final int maxExplorationMinutes;

  /// Elementos a ignorar durante exploracion
  final List<String> ignoredElements;

  /// Elementos prioritarios a explorar primero
  final List<String> priorityElements;

  const ExplorerConfig({
    this.maxDepth = 5,
    this.screenshotOnEveryStep = true,
    this.maxExplorationMinutes = 10,
    this.ignoredElements = const ['Back', 'Cancel', 'Cancelar'],
    this.priorityElements = const ['Nuevo', 'Agregar', 'Guardar', 'Submit'],
  });
}

/// Estado de una pantalla capturada
class ScreenState {
  final String screenName;
  final String? routeName;
  final List<InteractiveElement> interactiveElements;
  final String? screenshotPath;
  final DateTime capturedAt;
  final Map<String, dynamic> metadata;

  ScreenState({
    required this.screenName,
    this.routeName,
    required this.interactiveElements,
    this.screenshotPath,
    required this.capturedAt,
    this.metadata = const {},
  });

  @override
  String toString() =>
      'ScreenState($screenName, ${interactiveElements.length} elementos)';
}

/// Elemento interactivo encontrado en pantalla
class InteractiveElement {
  final String description;
  final ElementType type;
  final bool isEnabled;
  final Rect? bounds;
  final String? semanticLabel;

  InteractiveElement({
    required this.description,
    required this.type,
    required this.isEnabled,
    this.bounds,
    this.semanticLabel,
  });

  @override
  String toString() => 'Element($type: $description)';
}

enum ElementType {
  button,
  textField,
  dropdown,
  listItem,
  navigationItem,
  fab,
  link,
  checkbox,
  radio,
  slider,
  unknown,
}

/// Explorador autonomo de la aplicacion
class AutonomousExplorer {
  final PatrolTester $;
  final ExplorerConfig config;
  final List<ScreenState> visitedScreens = [];
  final Set<String> visitedPaths = {};
  final List<String> explorationLog = [];

  AutonomousExplorer(this.$, {this.config = const ExplorerConfig()});

  /// Inicia exploracion autonoma desde la pantalla actual
  Future<ExplorationReport> explore({
    int currentDepth = 0,
    String? parentPath,
  }) async {
    if (currentDepth >= config.maxDepth) {
      _log('Profundidad maxima alcanzada ($currentDepth)');
      return _generateReport();
    }

    // Capturar estado actual
    final currentState = await _captureCurrentState();
    final currentPath = '${parentPath ?? ''}/${currentState.screenName}';

    if (visitedPaths.contains(currentPath)) {
      _log('Pantalla ya visitada: $currentPath');
      return _generateReport();
    }

    visitedPaths.add(currentPath);
    visitedScreens.add(currentState);
    _log('Explorando: $currentPath (depth=$currentDepth)');

    // Screenshot si configurado
    if (config.screenshotOnEveryStep) {
      await _takeScreenshot(currentState.screenName);
    }

    // Encontrar elementos interactivos
    final elements = currentState.interactiveElements
        .where((e) => e.isEnabled)
        .where((e) => !config.ignoredElements.contains(e.description))
        .toList();

    // Priorizar elementos
    elements.sort((a, b) {
      final aPriority = config.priorityElements.contains(a.description) ? 0 : 1;
      final bPriority = config.priorityElements.contains(b.description) ? 0 : 1;
      return aPriority.compareTo(bPriority);
    });

    _log('Elementos encontrados: ${elements.length}');

    // Explorar cada elemento
    for (final element in elements) {
      try {
        _log('Interactuando con: ${element.description}');

        // Guardar estado antes de interaccion
        final beforeState = await _captureCurrentState();

        // Interactuar
        await _interactWithElement(element);
        await $.pumpAndSettle();

        // Verificar si cambio la pantalla
        final afterState = await _captureCurrentState();
        final screenChanged =
            beforeState.screenName != afterState.screenName ||
                _hasSignificantChange(beforeState, afterState);

        if (screenChanged) {
          // Explorar nueva pantalla recursivamente
          await explore(
            currentDepth: currentDepth + 1,
            parentPath: currentPath,
          );

          // Volver a pantalla anterior si es posible
          await _navigateBack();
        }
      } catch (e) {
        _log('Error interactuando con ${element.description}: $e');
      }
    }

    return _generateReport();
  }

  /// Captura el estado actual de la pantalla
  Future<ScreenState> _captureCurrentState() async {
    final elements = <InteractiveElement>[];

    // Buscar botones
    await _findElements<ElevatedButton>(elements, ElementType.button);
    await _findElements<FilledButton>(elements, ElementType.button);
    await _findElements<TextButton>(elements, ElementType.button);
    await _findElements<IconButton>(elements, ElementType.button);
    await _findElements<OutlinedButton>(elements, ElementType.button);

    // Buscar campos de texto
    await _findElements<TextField>(elements, ElementType.textField);
    await _findElements<TextFormField>(elements, ElementType.textField);

    // Buscar dropdowns
    await _findElements<DropdownButton>(elements, ElementType.dropdown);
    await _findElements<DropdownButtonFormField>(elements, ElementType.dropdown);

    // Buscar FAB
    await _findElements<FloatingActionButton>(elements, ElementType.fab);

    // Buscar items de lista
    await _findElements<ListTile>(elements, ElementType.listItem);

    // Determinar nombre de pantalla
    String screenName = 'UnknownScreen';
    try {
      // Intentar obtener del AppBar
      if ($(AppBar).exists) {
        final appBarText = $(AppBar).$(Text);
        if (appBarText.exists) {
          screenName = appBarText.text ?? 'Screen';
        }
      }
    } catch (_) {}

    return ScreenState(
      screenName: screenName,
      interactiveElements: elements,
      capturedAt: DateTime.now(),
    );
  }

  /// Encuentra elementos de un tipo especifico
  Future<void> _findElements<T extends Widget>(
    List<InteractiveElement> elements,
    ElementType type,
  ) async {
    try {
      final finder = $(find.byType(T));
      if (finder.exists) {
        // Obtener descripcion del elemento
        String description = T.toString();
        try {
          // Intentar obtener texto del elemento
          final textFinder = finder.$(Text);
          if (textFinder.exists) {
            description = textFinder.text ?? description;
          }
        } catch (_) {}

        elements.add(InteractiveElement(
          description: description,
          type: type,
          isEnabled: true, // TODO: detectar estado enabled
        ));
      }
    } catch (_) {
      // Elemento no encontrado, continuar
    }
  }

  /// Interactua con un elemento
  Future<void> _interactWithElement(InteractiveElement element) async {
    switch (element.type) {
      case ElementType.button:
      case ElementType.fab:
      case ElementType.listItem:
      case ElementType.link:
        // Tap
        try {
          await $(element.description).tap();
        } catch (_) {
          // Intentar por tipo
          await $(find.text(element.description)).tap();
        }
        break;

      case ElementType.textField:
        // Enfocar y escribir texto de prueba
        try {
          await $(element.description).enterText('Test Input');
        } catch (_) {}
        break;

      case ElementType.dropdown:
        // Abrir dropdown
        try {
          await $(element.description).tap();
          await $.pumpAndSettle();
          // Seleccionar primera opcion si existe
          final options = $(find.byType(DropdownMenuItem));
          if (options.exists) {
            await options.first.tap();
          }
        } catch (_) {}
        break;

      default:
        _log('Tipo de elemento no manejado: ${element.type}');
    }
  }

  /// Verifica si hubo cambio significativo entre estados
  bool _hasSignificantChange(ScreenState before, ScreenState after) {
    // Cambio en numero de elementos
    if ((before.interactiveElements.length - after.interactiveElements.length)
            .abs() >
        3) {
      return true;
    }

    // TODO: agregar mas heuristicas de deteccion de cambios

    return false;
  }

  /// Navega hacia atras
  Future<void> _navigateBack() async {
    try {
      // Intentar boton back de navegacion
      final backButton = $(find.byTooltip('Back'));
      if (backButton.exists) {
        await backButton.tap();
        await $.pumpAndSettle();
        return;
      }

      // Intentar boton de flecha atras
      final arrowBack = $(find.byIcon(Icons.arrow_back));
      if (arrowBack.exists) {
        await arrowBack.tap();
        await $.pumpAndSettle();
        return;
      }

      // Usar Navigator.pop via sistema
      await $.native.pressBack();
      await $.pumpAndSettle();
    } catch (e) {
      _log('No se pudo navegar atras: $e');
    }
  }

  /// Toma screenshot con nombre
  Future<void> _takeScreenshot(String name) async {
    try {
      final sanitizedName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      await $.takeScreenshot(name: sanitizedName);
      _log('Screenshot: $sanitizedName');
    } catch (e) {
      _log('Error tomando screenshot: $e');
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    explorationLog.add(logMessage);
    // ignore: avoid_print
    print('[EXPLORER] $logMessage');
  }

  /// Genera reporte de exploracion
  ExplorationReport _generateReport() {
    return ExplorationReport(
      visitedScreens: List.from(visitedScreens),
      visitedPaths: Set.from(visitedPaths),
      log: List.from(explorationLog),
      duration: Duration(
        milliseconds: visitedScreens.isNotEmpty
            ? DateTime.now()
                .difference(visitedScreens.first.capturedAt)
                .inMilliseconds
            : 0,
      ),
    );
  }
}

/// Reporte de exploracion autonoma
class ExplorationReport {
  final List<ScreenState> visitedScreens;
  final Set<String> visitedPaths;
  final List<String> log;
  final Duration duration;

  ExplorationReport({
    required this.visitedScreens,
    required this.visitedPaths,
    required this.log,
    required this.duration,
  });

  void print() {
    // ignore: avoid_print
    debugPrint('\n============ EXPLORATION REPORT ============');
    // ignore: avoid_print
    debugPrint('Duracion: ${duration.inSeconds}s');
    // ignore: avoid_print
    debugPrint('Pantallas visitadas: ${visitedScreens.length}');
    // ignore: avoid_print
    debugPrint('Rutas unicas: ${visitedPaths.length}');
    // ignore: avoid_print
    debugPrint('');
    // ignore: avoid_print
    debugPrint('Pantallas:');
    for (final screen in visitedScreens) {
      // ignore: avoid_print
      debugPrint('  - ${screen.screenName}');
    }
    // ignore: avoid_print
    debugPrint('');
    // ignore: avoid_print
    debugPrint('Rutas:');
    for (final path in visitedPaths) {
      // ignore: avoid_print
      debugPrint('  - $path');
    }
    // ignore: avoid_print
    debugPrint('=============================================\n');
  }
}
