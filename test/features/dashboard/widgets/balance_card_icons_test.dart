import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/shared/utils/icon_utils.dart';

/// Tests de renderizado de iconos en balance card
/// Verifica que IconUtils se integra correctamente con widgets
void main() {
  group('Balance Card Icons Integration', () {
    testWidgets('IconUtils.fromName renderiza icono correctamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Icon(IconUtils.fromName('payments')),
          ),
        ),
      );

      // Verifica que el icono se renderiza
      expect(find.byType(Icon), findsOneWidget);

      // Verifica que es el icono correcto
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, equals(Icons.payments));
    });

    testWidgets('Icono con nombre null usa fallback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Icon(IconUtils.fromName(null)),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, equals(Icons.category));
    });

    testWidgets('Simulación de lista de cuentas con iconos', (tester) async {
      // Simula el patrón usado en dashboard_screen
      final accountData = [
        {'name': 'Efectivo', 'icon': 'payments', 'balance': 50000.0},
        {'name': 'Banco', 'icon': 'account_balance', 'balance': 150000.0},
        {'name': 'Ahorros', 'icon': 'savings', 'balance': 300000.0},
        {'name': 'Tarjeta', 'icon': 'credit_card', 'balance': -25000.0},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: accountData.map((account) {
                return Row(
                  children: [
                    Icon(
                      IconUtils.fromName(account['icon'] as String),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(account['name'] as String),
                    const Spacer(),
                    Text('\$${account['balance']}'),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );

      // Verifica que hay 4 iconos renderizados
      expect(find.byType(Icon), findsNWidgets(4));

      // Verifica cada icono específico
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons[0].icon, equals(Icons.payments));
      expect(icons[1].icon, equals(Icons.account_balance));
      expect(icons[2].icon, equals(Icons.savings));
      expect(icons[3].icon, equals(Icons.credit_card));
    });

    testWidgets('Icono inválido no crashea el widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Icon(IconUtils.fromName('icono_que_no_existe')),
          ),
        ),
      );

      // No debe haber errores y debe mostrar el fallback
      expect(find.byType(Icon), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, equals(Icons.category));
    });

    testWidgets('forAccountType prioriza icono personalizado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                // Con icono personalizado
                Icon(IconUtils.forAccountType('restaurant', 'account_balance')),
                // Sin icono personalizado (usa tipo)
                Icon(IconUtils.forAccountType(null, 'credit_card')),
              ],
            ),
          ),
        ),
      );

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons[0].icon, equals(Icons.restaurant));
      expect(icons[1].icon, equals(Icons.credit_card));
    });

    testWidgets('Iconos con color y tamaño personalizados', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Icon(
              IconUtils.fromName('trending_up'),
              color: Colors.green,
              size: 32,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, equals(Icons.trending_up));
      expect(iconWidget.color, equals(Colors.green));
      expect(iconWidget.size, equals(32));
    });
  });

  group('Regresión: Bug de texto en lugar de icono', () {
    testWidgets('NO debe mostrar texto "attach_money" como string', (tester) async {
      // Este test verifica que el bug está resuelto
      // Antes: Text('attach_money ${nombre}')
      // Ahora: Row(Icon(...), Text(nombre))

      const iconName = 'attach_money';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(IconUtils.fromName(iconName)),
                const Text('Cuenta'),
              ],
            ),
          ),
        ),
      );

      // Verifica que NO existe el texto "attach_money" como string visible
      expect(find.text('attach_money'), findsNothing);
      expect(find.text('attach_money Cuenta'), findsNothing);

      // Verifica que SÍ existe el icono renderizado
      expect(find.byType(Icon), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, equals(Icons.attach_money));
    });

    testWidgets('Fallback emoji 🏦 ya no es necesario', (tester) async {
      // Antes: '${account.icon ?? '🏦'} ${account.name}:'
      // Ahora: Icon con fallback apropiado

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(
                  IconUtils.fromName(null, fallback: Icons.account_balance),
                ),
                const Text('Cuenta Sin Icono'),
              ],
            ),
          ),
        ),
      );

      // Verifica que NO hay emoji como texto
      expect(find.text('🏦'), findsNothing);

      // Verifica que hay un icono Material proper
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, equals(Icons.account_balance));
    });
  });
}
