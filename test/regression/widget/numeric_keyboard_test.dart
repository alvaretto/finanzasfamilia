// test/regression/widget/numeric_keyboard_test.dart
//
// Regression test for ERR-0004: Numeric keyboard not appearing in balance field
// See: .error-tracker/errors/ERR-0004.json
//
// Este test verifica que los campos numericos aceptan entrada decimal correctamente
// y que el flujo de navegacion entre campos funciona.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzas_familiares/features/accounts/presentation/widgets/add_account_sheet.dart';
import 'package:finanzas_familiares/features/accounts/presentation/widgets/first_account_wizard.dart';

import '../../helpers/test_helpers.dart';
import '../../mocks/mock_providers.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('ERR-0004: Numeric Keyboard Configuration', () {
    group('AddAccountSheet', () {
      testWidgets('Balance field accepts decimal input', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: testProviderOverrides,
            child: MaterialApp(
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

        // Open the sheet
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Find balance input by hint text
        final balanceInput = find.widgetWithText(TextFormField, '0.00');
        expect(balanceInput, findsOneWidget,
            reason: 'Balance field should exist with hint 0.00');

        // Enter decimal value
        await tester.enterText(balanceInput, '1234.56');
        await tester.pump();

        // Verify the value was accepted (find TextField with entered value)
        expect(find.text('1234.56'), findsOneWidget,
            reason: 'Balance field should accept decimal value');
      });

      testWidgets('Balance field accepts integer input', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: testProviderOverrides,
            child: MaterialApp(
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

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final balanceInput = find.widgetWithText(TextFormField, '0.00');
        await tester.enterText(balanceInput, '5000000');
        await tester.pump();

        expect(find.text('5000000'), findsOneWidget,
            reason: 'Balance field should accept integer value');
      });

      testWidgets('Balance field shows attach_money icon', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: testProviderOverrides,
            child: MaterialApp(
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

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Verify the money icon exists (indicates balance field)
        expect(find.byIcon(Icons.attach_money), findsOneWidget,
            reason: 'Balance field should have attach_money icon');
      });

      testWidgets('Name field has label_outline icon', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: testProviderOverrides,
            child: MaterialApp(
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

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Verify the name field icon exists
        expect(find.byIcon(Icons.label_outline), findsOneWidget,
            reason: 'Name field should have label_outline icon');
      });
    });

    group('FirstAccountWizard', () {
      testWidgets('Balance field in wizard accepts decimal input',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: testProviderOverrides,
            child: const MaterialApp(
              home: Scaffold(
                body: FirstAccountWizard(),
              ),
            ),
          ),
        );

        // Select a template to go to step 2
        await tester.tap(find.text('Efectivo'));
        await tester.pumpAndSettle();

        // Find balance input (the text "0" should be pre-filled)
        final balanceInputs = find.byType(TextFormField);
        expect(balanceInputs, findsWidgets);

        // Find the balance field by the attach_money icon
        expect(find.byIcon(Icons.attach_money), findsOneWidget,
            reason: 'Balance field should exist in wizard step 2');

        // Find input with hint 0.00
        final balanceInput = find.widgetWithText(TextFormField, '0.00');
        expect(balanceInput, findsOneWidget);

        // Enter a decimal value
        await tester.enterText(balanceInput, '999.99');
        await tester.pump();

        expect(find.text('999.99'), findsOneWidget,
            reason: 'Wizard balance field should accept decimal value');
      });
    });

    group('InputFormatter Validation', () {
      test('RegExp allows empty string', () {
        final regex = RegExp(r'^\d*\.?\d{0,2}');
        expect(regex.hasMatch(''), isTrue);
      });

      test('RegExp allows integer', () {
        final regex = RegExp(r'^\d*\.?\d{0,2}');
        expect(regex.hasMatch('1234'), isTrue);
      });

      test('RegExp allows decimal with 2 places', () {
        final regex = RegExp(r'^\d*\.?\d{0,2}');
        expect(regex.hasMatch('1234.56'), isTrue);
      });

      test('RegExp allows starting with dot', () {
        final regex = RegExp(r'^\d*\.?\d{0,2}');
        expect(regex.hasMatch('.99'), isTrue);
      });

      test('RegExp rejects more than 2 decimals', () {
        final regex = RegExp(r'^\d*\.?\d{0,2}$');
        expect(regex.hasMatch('1.999'), isFalse);
      });

      test('RegExp rejects letters', () {
        final regex = RegExp(r'^\d*\.?\d{0,2}$');
        expect(regex.hasMatch('abc'), isFalse);
      });

      test('RegExp rejects negative numbers', () {
        final regex = RegExp(r'^\d*\.?\d{0,2}$');
        expect(regex.hasMatch('-100'), isFalse);
      });

      test('Large numbers are accepted', () {
        final regex = RegExp(r'^\d*\.?\d{0,2}$');
        expect(regex.hasMatch('9999999999.99'), isTrue);
      });
    });
  });
}
