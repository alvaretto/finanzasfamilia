import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finanzas_familiares/presentation/screens/notification_settings_screen.dart';
import 'package:finanzas_familiares/application/providers/notification_provider.dart';

void main() {
  group('NotificationSettingsScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          // Mockear el provider con un valor fijo para evitar dependencias async
          notificationSettingsNotifierProvider.overrideWith(
            () => _MockNotificationSettingsNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: NotificationSettingsScreen(),
        ),
      );
    }

    testWidgets('muestra título Notificaciones', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Notificaciones'), findsAtLeast(1));
    });

    testWidgets('muestra switch de notificaciones globales', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Activar/desactivar todas las notificaciones'),
          findsOneWidget);
    });

    testWidgets('muestra sección de alertas de presupuesto', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Alertas de Presupuesto'), findsOneWidget);
      expect(find.text('Alertas de presupuesto'), findsOneWidget);
    });

    testWidgets('muestra sección de recordatorios', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recordatorios'), findsOneWidget);
      expect(find.text('Pagos recurrentes'), findsOneWidget);
      expect(find.text('Recordatorio diario'), findsOneWidget);
    });

    testWidgets('muestra información explicativa', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Las notificaciones te ayudan'),
        findsOneWidget,
      );
    });

    testWidgets('muestra switches para cada opción', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Debe haber al menos 4 switches (global, budget, recurring, daily)
      final switches = find.byType(Switch);
      expect(switches, findsAtLeast(4));
    });

    testWidgets('muestra iconos para cada opción', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pie_chart), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
      expect(find.byIcon(Icons.today), findsOneWidget);
    });
  });
}

/// Mock del NotificationSettingsNotifier para tests
class _MockNotificationSettingsNotifier extends NotificationSettingsNotifier {
  @override
  Future<NotificationSettings> build() async {
    // Devolver configuración por defecto inmediatamente
    return const NotificationSettings(
      globalEnabled: true,
      budgetAlertsEnabled: true,
      recurringRemindersEnabled: true,
      dailyReminderEnabled: false,
      dailyReminderHour: 20,
    );
  }

  @override
  Future<void> setGlobalEnabled(bool enabled) async {
    state = AsyncData(state.value!.copyWith(globalEnabled: enabled));
  }

  @override
  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    state = AsyncData(state.value!.copyWith(budgetAlertsEnabled: enabled));
  }

  @override
  Future<void> setRecurringRemindersEnabled(bool enabled) async {
    state = AsyncData(state.value!.copyWith(recurringRemindersEnabled: enabled));
  }

  @override
  Future<void> setDailyReminderEnabled(bool enabled) async {
    state = AsyncData(state.value!.copyWith(dailyReminderEnabled: enabled));
  }

  @override
  Future<void> setDailyReminderHour(int hour) async {
    state = AsyncData(state.value!.copyWith(dailyReminderHour: hour));
  }
}
