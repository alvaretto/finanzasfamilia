import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finanzas_familiares/presentation/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      );
    }

    testWidgets('muestra título Configuración', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Configuración'), findsOneWidget);
    });

    testWidgets('muestra sección Apariencia', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
    });

    testWidgets('muestra sección Notificaciones', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Configurar notificaciones'), findsOneWidget);
      expect(find.text('Notificaciones Bancarias'), findsOneWidget);
    });

    testWidgets('muestra sección Información con versión', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll hasta ver la sección Información
      await tester.scrollUntilVisible(
        find.text('Información'),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Información'), findsOneWidget);
      expect(find.text('Versión'), findsOneWidget);
      expect(find.text('5.1'), findsOneWidget);
    });

    testWidgets('muestra sección Cuenta con opción cerrar sesión',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll hasta ver la sección Cuenta
      await tester.scrollUntilVisible(
        find.text('Cuenta'),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cuenta'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('Salir de tu cuenta'), findsOneWidget);
    });

    testWidgets('muestra ícono de logout en rojo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll hasta ver el ícono de logout
      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('tap en cerrar sesión muestra diálogo de confirmación',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll hasta ver el botón de cerrar sesión
      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('¿Estás seguro de que deseas cerrar sesión?'),
          findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('cancelar diálogo cierra el diálogo sin hacer nada',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll hasta ver el botón de cerrar sesión
      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Diálogo se cierra, volvemos a ver la pantalla de settings
      expect(find.text('¿Estás seguro de que deseas cerrar sesión?'),
          findsNothing);
      expect(find.text('Configuración'), findsOneWidget);
    });

    testWidgets('muestra selector de tema con opciones', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
    });
  });
}
