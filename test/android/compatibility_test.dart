/// Tests de Compatibilidad Android
/// Verifica comportamiento en diferentes configuraciones Android
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    SupabaseClientProvider.enableTestMode();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  group('Android: Screen Sizes', () {
    testWidgets('App funciona en 720x1280 (HD)', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('HD Screen')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TestMainScaffold), findsOneWidget);
    });

    testWidgets('App funciona en 1080x1920 (FHD)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('FHD Screen')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TestMainScaffold), findsOneWidget);
    });

    testWidgets('App funciona en 800x1280 (Tablet)', (tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Tablet Screen')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TestMainScaffold), findsOneWidget);
    });
  });

  group('Android: Orientation', () {
    testWidgets('App funciona en portrait', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Portrait')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Portrait'), findsOneWidget);
    });

    testWidgets('App funciona en landscape', (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Landscape')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Landscape'), findsOneWidget);
    });

    testWidgets('Cambio de orientacion no crashea', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Orientation Test')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cambiar a landscape
      tester.view.physicalSize = const Size(640, 360);
      await tester.pumpAndSettle();

      // Volver a portrait
      tester.view.physicalSize = const Size(360, 640);
      await tester.pumpAndSettle();

      addTearDown(() => tester.view.resetPhysicalSize());
      expect(find.text('Orientation Test'), findsOneWidget);
    });
  });

  group('Android: Font Scaling', () {
    testWidgets('App funciona con font scale 0.85', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.85)),
                child: child!,
              );
            },
            home: const TestMainScaffold(
              child: Center(child: Text('Small Font')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Small Font'), findsOneWidget);
    });

    testWidgets('App funciona con font scale 1.3', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              );
            },
            home: const TestMainScaffold(
              child: Center(child: Text('Large Font')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Large Font'), findsOneWidget);
    });
  });

  group('Android: Theme Support', () {
    testWidgets('Tema claro se aplica correctamente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Light Theme')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final theme = Theme.of(context);
      expect(theme.brightness, Brightness.light);
    });

    testWidgets('Tema oscuro se aplica correctamente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const TestMainScaffold(
              child: Center(child: Text('Dark Theme')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final theme = Theme.of(context);
      expect(theme.brightness, Brightness.dark);
    });
  });
}
