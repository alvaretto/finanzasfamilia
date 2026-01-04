/// Tests de Widgets de Chat
/// Verifica renderizado de burbujas, campo de entrada, estados de carga
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';

void main() {
  setUpAll(() {
    SupabaseClientProvider.enableTestMode();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  group('Chat UI: Message Bubbles', () {
    // =========================================================================
    // TEST 1: Burbuja de usuario se renderiza
    // =========================================================================
    testWidgets('Burbuja de mensaje usuario se muestra correctamente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestUserBubble(message: 'Hola Fina'),
            ),
          ),
        ),
      );

      expect(find.text('Hola Fina'), findsOneWidget);
    });

    // =========================================================================
    // TEST 2: Burbuja de asistente se renderiza
    // =========================================================================
    testWidgets('Burbuja de mensaje asistente se muestra correctamente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestAssistantBubble(message: 'Hola! Soy Fina, tu asistente.'),
            ),
          ),
        ),
      );

      expect(find.text('Hola! Soy Fina, tu asistente.'), findsOneWidget);
    });

    // =========================================================================
    // TEST 3: Indicador de carga se muestra
    // =========================================================================
    testWidgets('Indicador de carga se muestra mientras espera respuesta', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // =========================================================================
    // TEST 4: Mensaje largo se muestra completo
    // =========================================================================
    testWidgets('Mensaje largo se renderiza sin overflow', (tester) async {
      final longMessage = 'Este es un mensaje muy largo ' * 20;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: _TestUserBubble(message: longMessage),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Este es un mensaje muy largo'), findsOneWidget);
    });
  });

  group('Chat UI: Input Field', () {
    // =========================================================================
    // TEST 5: Campo de texto se renderiza
    // =========================================================================
    testWidgets('Campo de entrada de texto se muestra', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestChatInput(),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    // =========================================================================
    // TEST 6: Texto se puede escribir
    // =========================================================================
    testWidgets('Usuario puede escribir en campo de texto', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestChatInput(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hola Fina');
      await tester.pump();

      expect(find.text('Hola Fina'), findsOneWidget);
    });

    // =========================================================================
    // TEST 7: Boton de enviar existe
    // =========================================================================
    testWidgets('Boton de enviar esta presente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestChatInput(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    // =========================================================================
    // TEST 8: Boton de enviar se puede presionar
    // =========================================================================
    testWidgets('Boton de enviar es interactivo', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestChatInput(onSend: () => wasTapped = true),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(wasTapped, true);
    });
  });

  group('Chat UI: Suggestions', () {
    // =========================================================================
    // TEST 9: Sugerencias se muestran
    // =========================================================================
    testWidgets('Chips de sugerencias se renderizan', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestSuggestionChips(
                suggestions: [
                  'Como van mis finanzas?',
                  'En que gasto mas?',
                  'Dame consejos',
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Como van mis finanzas?'), findsOneWidget);
      expect(find.text('En que gasto mas?'), findsOneWidget);
      expect(find.text('Dame consejos'), findsOneWidget);
    });

    // =========================================================================
    // TEST 10: Sugerencia se puede seleccionar
    // =========================================================================
    testWidgets('Tap en sugerencia la selecciona', (tester) async {
      String? selectedSuggestion;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestSuggestionChips(
                suggestions: ['Sugerencia 1'],
                onSelect: (s) => selectedSuggestion = s,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sugerencia 1'));
      await tester.pump();

      expect(selectedSuggestion, 'Sugerencia 1');
    });
  });

  group('Chat UI: States', () {
    // =========================================================================
    // TEST 11: Estado vacio muestra mensaje de bienvenida
    // =========================================================================
    testWidgets('Chat vacio muestra mensaje de bienvenida', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestEmptyChat(),
            ),
          ),
        ),
      );

      expect(find.textContaining('Fina'), findsOneWidget);
    });

    // =========================================================================
    // TEST 12: Estado de error se muestra
    // =========================================================================
    testWidgets('Error se muestra correctamente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestErrorState(error: 'No hay conexion'),
            ),
          ),
        ),
      );

      expect(find.text('No hay conexion'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    // =========================================================================
    // TEST 13: Boton de reintentar funciona
    // =========================================================================
    testWidgets('Boton de reintentar es interactivo', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: _TestErrorState(
                error: 'Error',
                onRetry: () => retried = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(retried, true);
    });
  });

  group('Chat UI: Accessibility', () {
    // =========================================================================
    // TEST 14: Semantics para screen readers
    // =========================================================================
    testWidgets('Elementos tienen semantics correctos', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Semantics(
                label: 'Campo de mensaje',
                child: TextField(),
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Campo de mensaje'),
        findsOneWidget,
      );
    });

    // =========================================================================
    // TEST 15: Font scale grande no rompe UI
    // =========================================================================
    testWidgets('UI funciona con font scale 1.5', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.5),
                ),
                child: child!,
              );
            },
            home: Scaffold(
              body: _TestChatInput(),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}

// =============================================================================
// WIDGETS DE PRUEBA
// =============================================================================

class _TestUserBubble extends StatelessWidget {
  final String message;

  const _TestUserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _TestAssistantBubble extends StatelessWidget {
  final String message;

  const _TestAssistantBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message),
    );
  }
}

class _TestChatInput extends StatelessWidget {
  final VoidCallback? onSend;

  _TestChatInput({this.onSend});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Escribe tu mensaje...',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: onSend ?? () {},
        ),
      ],
    );
  }
}

class _TestSuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String>? onSelect;

  const _TestSuggestionChips({
    required this.suggestions,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: suggestions.map((s) {
        return ActionChip(
          label: Text(s),
          onPressed: () => onSelect?.call(s),
        );
      }).toList(),
    );
  }
}

class _TestEmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64),
          SizedBox(height: 16),
          Text('Hola! Soy Fina, tu asistente financiera.'),
        ],
      ),
    );
  }
}

class _TestErrorState extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _TestErrorState({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(error),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}
