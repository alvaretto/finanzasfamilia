import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finanzas_familiares/presentation/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingScreen', () {
    Widget createTestWidget({VoidCallback? onComplete}) {
      return ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(
            onComplete: onComplete ?? () {},
          ),
        ),
      );
    }

    testWidgets('muestra página de bienvenida inicialmente', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido a'), findsOneWidget);
      expect(find.text('Finanzas Familiares'), findsOneWidget);
    });

    testWidgets('muestra indicadores de página', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Debe haber 4 indicadores (uno por cada paso)
      final indicators = find.byType(AnimatedContainer);
      expect(indicators, findsWidgets);
    });

    testWidgets('muestra botón Siguiente', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Siguiente'), findsOneWidget);
    });

    testWidgets('navega a siguiente página al presionar Siguiente',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Segunda página: Características
      expect(find.text('Control Total'), findsOneWidget);
    });

    testWidgets('muestra botón Omitir', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Omitir'), findsOneWidget);
    });

    testWidgets('puede hacer swipe para cambiar de página', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Swipe a la izquierda para avanzar
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Control Total'), findsOneWidget);
    });

    testWidgets('muestra botón Comenzar en última página', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navegar a la última página (4 páginas, 3 taps)
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Comenzar'), findsOneWidget);
      expect(find.text('Omitir'), findsNothing);
    });

    testWidgets('llama onComplete al presionar Comenzar', (tester) async {
      var completeCalled = false;

      await tester.pumpWidget(createTestWidget(
        onComplete: () => completeCalled = true,
      ));
      await tester.pumpAndSettle();

      // Navegar a la última página
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      expect(completeCalled, isTrue);
    });

    testWidgets('llama onComplete al presionar Omitir', (tester) async {
      var completeCalled = false;

      await tester.pumpWidget(createTestWidget(
        onComplete: () => completeCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      expect(completeCalled, isTrue);
    });
  });

  group('OnboardingPages', () {
    testWidgets('página de características muestra íconos', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(onComplete: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navegar a página de características
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.offline_bolt), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('página de cuentas muestra ejemplos colombianos',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(onComplete: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navegar a página de cuentas (3ra página)
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Nequi'), findsOneWidget);
      expect(find.text('Davivienda'), findsOneWidget);
      expect(find.text('Efectivo'), findsOneWidget);
    });
  });
}
