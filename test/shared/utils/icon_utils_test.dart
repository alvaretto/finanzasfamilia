import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/shared/utils/icon_utils.dart';

void main() {
  group('IconUtils', () {
    group('fromName', () {
      test('retorna IconData correcto para iconos de cuentas', () {
        expect(IconUtils.fromName('payments'), equals(Icons.payments));
        expect(IconUtils.fromName('account_balance'), equals(Icons.account_balance));
        expect(IconUtils.fromName('account_balance_wallet'), equals(Icons.account_balance_wallet));
        expect(IconUtils.fromName('savings'), equals(Icons.savings));
        expect(IconUtils.fromName('trending_up'), equals(Icons.trending_up));
        expect(IconUtils.fromName('credit_card'), equals(Icons.credit_card));
      });

      test('retorna IconData correcto para iconos de categorías', () {
        expect(IconUtils.fromName('restaurant'), equals(Icons.restaurant));
        expect(IconUtils.fromName('local_grocery_store'), equals(Icons.local_grocery_store));
        expect(IconUtils.fromName('directions_car'), equals(Icons.directions_car));
        expect(IconUtils.fromName('attach_money'), equals(Icons.attach_money));
        expect(IconUtils.fromName('work'), equals(Icons.work));
      });

      test('retorna fallback para nombre null', () {
        expect(IconUtils.fromName(null), equals(Icons.category));
      });

      test('retorna fallback para string vacío', () {
        expect(IconUtils.fromName(''), equals(Icons.category));
      });

      test('retorna fallback para icono no existente', () {
        expect(IconUtils.fromName('icono_inexistente'), equals(Icons.category));
      });

      test('respeta fallback personalizado', () {
        expect(
          IconUtils.fromName('no_existe', fallback: Icons.error),
          equals(Icons.error),
        );
        expect(
          IconUtils.fromName(null, fallback: Icons.account_balance),
          equals(Icons.account_balance),
        );
      });
    });

    group('hasIcon', () {
      test('retorna true para iconos existentes', () {
        expect(IconUtils.hasIcon('payments'), isTrue);
        expect(IconUtils.hasIcon('account_balance'), isTrue);
        expect(IconUtils.hasIcon('restaurant'), isTrue);
      });

      test('retorna false para iconos inexistentes', () {
        expect(IconUtils.hasIcon('icono_falso'), isFalse);
        expect(IconUtils.hasIcon(''), isFalse);
      });
    });

    group('availableIcons', () {
      test('retorna lista no vacía', () {
        final icons = IconUtils.availableIcons;
        expect(icons, isNotEmpty);
        expect(icons.length, greaterThan(30));
      });

      test('contiene iconos esenciales de cuentas', () {
        final icons = IconUtils.availableIcons;
        expect(icons, contains('payments'));
        expect(icons, contains('account_balance'));
        expect(icons, contains('credit_card'));
        expect(icons, contains('savings'));
      });
    });

    group('forAccountType', () {
      test('usa icono personalizado si está disponible', () {
        expect(
          IconUtils.forAccountType('restaurant', 'account_balance'),
          equals(Icons.restaurant),
        );
      });

      test('usa icono del tipo si personalizado es null', () {
        expect(
          IconUtils.forAccountType(null, 'credit_card'),
          equals(Icons.credit_card),
        );
      });

      test('usa icono del tipo si personalizado está vacío', () {
        expect(
          IconUtils.forAccountType('', 'savings'),
          equals(Icons.savings),
        );
      });

      test('usa icono del tipo si personalizado no existe', () {
        expect(
          IconUtils.forAccountType('icono_invalido', 'payments'),
          equals(Icons.payments),
        );
      });

      test('retorna account_balance si ningún icono existe', () {
        expect(
          IconUtils.forAccountType('invalido', 'tambien_invalido'),
          equals(Icons.account_balance),
        );
      });
    });

    group('Iconos de AccountType', () {
      test('todos los iconos de AccountType están disponibles', () {
        // Estos son los iconos definidos en AccountType.icon
        final accountTypeIcons = [
          'payments',           // cash
          'account_balance',    // bank
          'account_balance_wallet', // wallet
          'savings',            // savings
          'trending_up',        // investment
          'credit_card',        // credit
          'real_estate_agent',  // loan
          'arrow_circle_down',  // receivable
          'arrow_circle_up',    // payable
        ];

        for (final iconName in accountTypeIcons) {
          expect(
            IconUtils.hasIcon(iconName),
            isTrue,
            reason: 'Icono "$iconName" debe estar disponible',
          );
          expect(
            IconUtils.fromName(iconName),
            isNot(equals(Icons.category)),
            reason: 'Icono "$iconName" no debe retornar fallback',
          );
        }
      });
    });
  });
}
