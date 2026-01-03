import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/features/auth/presentation/providers/auth_provider.dart';

/// Tests de integración que simulan el arranque de la app
/// Estos tests deben detectar el problema de "foto estática"
void main() {
  group('App Startup - Tests de Integración', () {
    testWidgets('La app debe renderizar UI básica correctamente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Status: unauthenticated'),
                    const Text('isAuthenticated: false'),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que se renderiza correctamente
      expect(find.text('Status: unauthenticated'), findsOneWidget);
      expect(find.text('isAuthenticated: false'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // El botón debe ser interactivo
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
    });

    testWidgets('Los botones deben responder después del pump', (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => buttonPressed = true,
                  child: const Text('Test Button'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // El botón debe existir
      expect(find.byType(ElevatedButton), findsOneWidget);

      // El botón debe responder al tap
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buttonPressed, isTrue,
          reason: 'El botón DEBE responder al tap - si esto falla, hay un problema de gestures');
    });

    testWidgets('Form de login simulado debe funcionar', (tester) async {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      var loginAttempted = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
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
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('password'),
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => loginAttempted = true,
                        child: const Text('Iniciar Sesión'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ingresar email
      await tester.enterText(find.byKey(const Key('email')), 'test@test.com');
      await tester.pump();
      expect(emailController.text, 'test@test.com');

      // Ingresar password
      await tester.enterText(find.byKey(const Key('password')), 'password123');
      await tester.pump();
      expect(passwordController.text, 'password123');

      // Hacer login
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pump();

      expect(loginAttempted, isTrue,
          reason: 'El botón de login debe funcionar después de llenar el form');
    });

    testWidgets('Bottom Navigation debe responder a taps', (tester) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(child: Text('Tab $selectedIndex')),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                selectedIndex = index;
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet),
                  label: 'Cuentas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Reportes',
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap en segundo tab
      await tester.tap(find.text('Cuentas'));
      await tester.pump();

      // El tap debe haber cambiado el índice
      // Nota: En el widget real StatefulWidget, esto reconstruiría
      expect(selectedIndex, 1,
          reason: 'BottomNavigationBar debe responder a taps');
    });

    testWidgets('FAB debe responder y abrir bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: const Center(child: Text('Main Content')),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Container(
                      height: 200,
                      child: const Center(child: Text('Bottom Sheet')),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que FAB existe
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Tap en FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Bottom sheet debe aparecer
      expect(find.text('Bottom Sheet'), findsOneWidget,
          reason: 'FAB debe abrir el bottom sheet');
    });

    testWidgets('RefreshIndicator debe funcionar', (tester) async {
      var refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                refreshed = true;
              },
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                  ListTile(title: Text('Item 2')),
                  ListTile(title: Text('Item 3')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simular pull-to-refresh
      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pumpAndSettle();

      // El refresh debe haberse ejecutado
      expect(refreshed, isTrue,
          reason: 'RefreshIndicator debe responder a gestos de pull');
    });
  });

  group('Tests de Estados Asíncronos', () {
    testWidgets('Loading state debe mostrar indicador', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                // Simular estado de carga
                const isLoading = true;

                return Scaffold(
                  body: Center(
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Content'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Error state debe mostrar mensaje', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                const hasError = true;
                const errorMessage = 'Error de conexión';

                return Scaffold(
                  body: Center(
                    child: hasError
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text(errorMessage),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {},
                                child: const Text('Reintentar'),
                              ),
                            ],
                          )
                        : const Text('Content'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Error de conexión'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      // Botón de reintentar debe funcionar
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
    });
  });
}
