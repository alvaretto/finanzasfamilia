import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';

/// Tests agresivos de widgets interactivos
/// Estos tests verifican que los botones, forms y gestures funcionen
void main() {
  group('Tests de Interactividad Básica', () {
    testWidgets('ElevatedButton debe responder a taps', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => tapCount++,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      // Tap múltiples veces para verificar que no hay bloqueo
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
      }

      expect(tapCount, 5,
          reason: 'El botón debe responder a todos los taps');
    });

    testWidgets('TextFormField debe aceptar input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ),
          ),
        ),
      );

      // Tap en el campo
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Escribir texto
      await tester.enterText(find.byType(TextField), 'test@email.com');
      await tester.pump();

      expect(find.text('test@email.com'), findsOneWidget,
          reason: 'El texto ingresado debe aparecer');
    });

    testWidgets('InkWell debe responder a taps', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkWell(
              onTap: () => tapped = true,
              child: const SizedBox(
                width: 100,
                height: 100,
                child: Text('Tap me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue,
          reason: 'InkWell debe detectar el tap');
    });

    testWidgets('GestureDetector debe responder a gestos', (tester) async {
      var gestureDetected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => gestureDetected = true,
              child: Container(
                width: 200,
                height: 200,
                color: Colors.blue,
                child: const Center(child: Text('Gesture')),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Gesture'));
      await tester.pump();

      expect(gestureDetected, isTrue);
    });

    testWidgets('IconButton debe responder', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(pressed, isTrue);
    });
  });

  group('Tests de Formularios', () {
    testWidgets('Form con validación debe funcionar', (tester) async {
      final formKey = GlobalKey<FormState>();
      var formValid = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        formValid = formKey.currentState?.validate() ?? false;
                      },
                      child: const Text('Validar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Validar sin llenar el campo
      await tester.tap(find.text('Validar'));
      await tester.pump();

      expect(formValid, isFalse,
          reason: 'Formulario vacío no debe ser válido');
      expect(find.text('Requerido'), findsOneWidget,
          reason: 'Debe mostrar mensaje de error');

      // Llenar el campo y validar
      await tester.enterText(find.byType(TextFormField), 'test@test.com');
      await tester.tap(find.text('Validar'));
      await tester.pump();

      expect(formValid, isTrue,
          reason: 'Formulario con datos válidos debe pasar validación');
    });

    testWidgets('Múltiples campos deben ser independientes', (tester) async {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    key: const Key('email'),
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    key: const Key('password'),
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('email')), 'user@test.com');
      await tester.enterText(find.byKey(const Key('password')), 'secret123');
      await tester.pump();

      expect(emailController.text, 'user@test.com');
      expect(passwordController.text, 'secret123');
    });
  });

  group('Tests de Navegación Básica', () {
    testWidgets('Navigator.push debe funcionar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Text('Segunda pantalla'),
                      ),
                    ),
                  );
                },
                child: const Text('Ir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ir'));
      await tester.pumpAndSettle();

      expect(find.text('Segunda pantalla'), findsOneWidget,
          reason: 'Debe navegar a la segunda pantalla');
    });

    testWidgets('Navigator.pop debe funcionar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  const Text('Primera pantalla'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => Scaffold(
                            body: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Volver'),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Ir'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Navegar adelante
      await tester.tap(find.text('Ir'));
      await tester.pumpAndSettle();

      expect(find.text('Volver'), findsOneWidget);

      // Navegar atrás
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();

      expect(find.text('Primera pantalla'), findsOneWidget,
          reason: 'Debe regresar a la primera pantalla');
    });
  });

  group('Tests de BottomSheet', () {
    testWidgets('showModalBottomSheet debe abrir y cerrar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Container(
                      height: 200,
                      child: Column(
                        children: [
                          const Text('BottomSheet'),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('BottomSheet'), findsOneWidget,
          reason: 'BottomSheet debe abrirse');

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('BottomSheet'), findsNothing,
          reason: 'BottomSheet debe cerrarse');
    });
  });

  group('Tests de Scroll', () {
    testWidgets('ListView.builder debe crear items bajo demanda', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 50,
              itemBuilder: (_, i) => SizedBox(
                height: 100,
                child: Text('Item $i'),
              ),
            ),
          ),
        ),
      );

      // Verificar que el primer item está visible
      expect(find.text('Item 0'), findsOneWidget);

      // Scroll hacia abajo
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();

      // Después del scroll, items iniciales ya no están visibles
      // y se muestran otros items (ListView recicla widgets)
      expect(find.text('Item 0'), findsNothing,
          reason: 'Scroll debe mover los items fuera de la vista');
    });

    testWidgets('ListView debe scrollear', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, i) => ListTile(
                title: Text('ListItem $i'),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('ListItem 0'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump();

      // Debería mostrar items más abajo
      expect(find.text('ListItem 0'), findsNothing);
    });
  });

  group('Tests de Riverpod Consumer', () {
    testWidgets('ConsumerWidget debe reconstruirse con cambios de estado', (tester) async {
      final counterProvider = StateProvider<int>((ref) => 0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final count = ref.watch(counterProvider);
                return Scaffold(
                  body: Column(
                    children: [
                      Text('Count: $count'),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(counterProvider.notifier).state++;
                        },
                        child: const Text('Incrementar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.text('Incrementar'));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget,
          reason: 'Consumer debe actualizarse cuando el estado cambia');

      // Múltiples incrementos
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('Incrementar'));
        await tester.pump();
      }

      expect(find.text('Count: 11'), findsOneWidget);
    });
  });
}
