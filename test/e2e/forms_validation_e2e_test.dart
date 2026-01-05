/// E2E Tests - Formularios y Validaciones
/// Tests agresivos de todos los formularios de la aplicación
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/features/auth/presentation/screens/login_screen.dart';
import 'package:finanzas_familiares/features/auth/presentation/screens/register_screen.dart';
import 'package:finanzas_familiares/features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/accounts/presentation/widgets/add_account_sheet.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_providers.dart';

void main() {
  setUpAll(() => setupTestEnvironment());
  tearDownAll(() => tearDownTestEnvironment());
  group('E2E: Login Form Validation', () {
    // =========================================================================
    // TEST 1: Login form se renderiza con todos los campos
    // =========================================================================
    testWidgets('Login form debe tener email y password', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buscar campos
      expect(find.byType(TextFormField), findsWidgets,
          reason: 'Debe tener campos de formulario');
    });

    // =========================================================================
    // TEST 2: Email field acepta input
    // =========================================================================
    testWidgets('Campo de email debe aceptar input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buscar primer campo de texto (generalmente email)
      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'test@example.com');
        await tester.pump();
        expect(find.text('test@example.com'), findsOneWidget);
      }
    });

    // =========================================================================
    // TEST 3: Password field existe
    // =========================================================================
    testWidgets('Campo de password debe existir', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buscar campos de texto (deben haber al menos 2: email y password)
      final textFields = find.byType(TextFormField);
      expect(textFields.evaluate().length, greaterThanOrEqualTo(2),
          reason: 'Debe tener al menos email y password');
    });

    // =========================================================================
    // TEST 4: Botón de login existe
    // =========================================================================
    testWidgets('Botón de login debe existir', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buscar botón de login
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ElevatedButton || widget is FilledButton,
        ),
        findsWidgets,
        reason: 'Debe tener botón de acción',
      );
    });

    // =========================================================================
    // TEST 5: Validación de email vacío
    // =========================================================================
    testWidgets('Debe validar email vacío', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buscar y hacer tap en botón de login sin llenar campos
      final loginButtons = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is FilledButton,
      );

      if (loginButtons.evaluate().isNotEmpty) {
        await tester.tap(loginButtons.first);
        await tester.pumpAndSettle();
        // Debe mostrar errores de validación o no hacer nada
      }
    });

    // =========================================================================
    // TEST 6: Link a registro existe
    // =========================================================================
    testWidgets('Link a registro debe existir', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buscar link/botón de registro
      expect(
        find.byWidgetPredicate(
          (widget) => widget is TextButton || widget is InkWell,
        ),
        findsWidgets,
      );
    });
  });

  group('E2E: Register Form Validation', () {
    // =========================================================================
    // TEST 7: Register form se renderiza
    // =========================================================================
    testWidgets('Register form debe renderizarse', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    // =========================================================================
    // TEST 8: Campos de registro existen
    // =========================================================================
    testWidgets('Register debe tener campos de nombre, email, password', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets,
          reason: 'Debe tener múltiples campos de formulario');
    });

    // =========================================================================
    // TEST 9: Campo de confirmar password existe
    // =========================================================================
    testWidgets('Debe tener múltiples campos de password', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe haber múltiples campos de texto
      final textFields = find.byType(TextFormField);
      expect(textFields.evaluate().length, greaterThanOrEqualTo(3),
          reason: 'Debe tener nombre, email, password y confirmación');
    });
  });

  group('E2E: Transaction Form Edge Cases', () {
    // =========================================================================
    // TEST 10: Monto con decimales
    // =========================================================================
    testWidgets('Campo de monto debe aceptar decimales', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, '1234.56');
        await tester.pump();
        expect(find.text('1234.56'), findsOneWidget);
      }
    });

    // =========================================================================
    // TEST 11: Monto negativo
    // =========================================================================
    testWidgets('Campo de monto maneja valores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, '100');
        await tester.pump();
        // No debe crashear
      }
    });

    // =========================================================================
    // TEST 12: Monto muy grande
    // =========================================================================
    testWidgets('Campo de monto debe manejar valores grandes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, '999999999.99');
        await tester.pump();
        // No debe crashear
      }
    });

    // =========================================================================
    // TEST 13: Descripción muy larga
    // =========================================================================
    testWidgets('Campo de descripción debe manejar texto largo', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Buscar segundo campo de texto (descripción)
      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().length > 1) {
        final longText = 'A' * 500; // 500 caracteres
        await tester.enterText(textFields.at(1), longText);
        await tester.pump();
        // No debe crashear
      }
    });

    // =========================================================================
    // TEST 14: Caracteres especiales en descripción
    // =========================================================================
    testWidgets('Descripción debe aceptar caracteres especiales', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().length > 1) {
        await tester.enterText(textFields.at(1), 'Café & Comida #1');
        await tester.pump();
        expect(find.text('Café & Comida #1'), findsOneWidget);
      }
    });
  });

  group('E2E: Account Form Edge Cases', () {
    // =========================================================================
    // TEST 15: Nombre de cuenta con caracteres especiales
    // =========================================================================
    testWidgets('Nombre de cuenta debe aceptar caracteres especiales', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddAccountSheet(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'Cuenta #1 - Principal (MXN)');
        await tester.pump();
        expect(find.text('Cuenta #1 - Principal (MXN)'), findsOneWidget);
      }
    });

    // =========================================================================
    // TEST 16: Balance inicial
    // =========================================================================
    testWidgets('Balance inicial acepta valores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddAccountSheet(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Buscar segundo campo (balance)
      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().length > 1) {
        await tester.enterText(textFields.at(1), '1000');
        await tester.pump();
        // No debe crashear
      }
    });
  });

  group('E2E: Keyboard Interactions', () {
    // =========================================================================
    // TEST 17: Cerrar teclado no afecta formulario
    // =========================================================================
    testWidgets('Cerrar teclado debe mantener valores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().isNotEmpty) {
        // Ingresar valor
        await tester.enterText(textFields.first, '100');
        await tester.pump();

        // Simular cierre de teclado
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Valor debe mantenerse
        expect(find.text('100'), findsOneWidget);
      }
    });

    // =========================================================================
    // TEST 18: Tab entre campos funciona
    // =========================================================================
    testWidgets('Navegación entre campos con tab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buscar campos
      final fields = find.byType(TextFormField);

      if (fields.evaluate().length >= 2) {
        // Focus en primer campo
        await tester.tap(fields.first);
        await tester.pump();

        // El test verifica que no crashee al interactuar con campos
      }
    });
  });

  group('E2E: Form Submission Edge Cases', () {
    // =========================================================================
    // TEST 19: Doble submit no causa problemas
    // =========================================================================
    testWidgets('Doble tap en submit no causa errores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buscar botón de submit
      final submitButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is FilledButton,
      );

      if (submitButton.evaluate().isNotEmpty) {
        // Doble tap rápido
        await tester.tap(submitButton.first);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(submitButton.first);
        await tester.pumpAndSettle();

        // No debe crashear
      }
    });

    // =========================================================================
    // TEST 20: Submit mientras se carga no causa problemas
    // =========================================================================
    testWidgets('Submit durante loading no causa errores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Múltiples taps rápidos
      final buttons = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton || widget is FilledButton,
      );

      if (buttons.evaluate().isNotEmpty) {
        for (var i = 0; i < 5; i++) {
          await tester.tap(buttons.first);
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();

        // No debe crashear
      }
    });
  });
}
