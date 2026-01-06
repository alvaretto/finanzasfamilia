import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/models/payment_enums.dart';

void main() {
  group('PaymentMethod', () {
    test('fromValue devuelve método correcto', () {
      expect(PaymentMethod.fromValue('credit'), PaymentMethod.credit);
      expect(PaymentMethod.fromValue('cash'), PaymentMethod.cash);
    });

    test('fromValue devuelve cash por defecto para valor inválido', () {
      expect(PaymentMethod.fromValue('invalid'), PaymentMethod.cash);
    });

    test('fromValue devuelve null para null', () {
      expect(PaymentMethod.fromValue(null), isNull);
    });

    test('cada método tiene displayName', () {
      expect(PaymentMethod.credit.displayName, 'Crédito');
      expect(PaymentMethod.cash.displayName, 'Contado');
    });
  });

  group('PaymentMedium', () {
    test('fromValue devuelve medio correcto', () {
      expect(PaymentMedium.fromValue('credit_card'), PaymentMedium.creditCard);
      expect(PaymentMedium.fromValue('cash'), PaymentMedium.cashMoney);
      expect(PaymentMedium.fromValue('bank_transfer'), PaymentMedium.bankTransfer);
      expect(PaymentMedium.fromValue('app_transfer'), PaymentMedium.appTransfer);
    });

    test('fromValue devuelve null para null', () {
      expect(PaymentMedium.fromValue(null), isNull);
    });

    test('forMethod filtra por método de pago', () {
      final creditMediums = PaymentMedium.forMethod(PaymentMethod.credit);
      final cashMediums = PaymentMedium.forMethod(PaymentMethod.cash);

      expect(creditMediums, contains(PaymentMedium.creditCard));
      expect(creditMediums, contains(PaymentMedium.fiado));
      expect(creditMediums, isNot(contains(PaymentMedium.cashMoney)));

      expect(cashMediums, contains(PaymentMedium.cashMoney));
      expect(cashMediums, contains(PaymentMedium.bankTransfer));
      expect(cashMediums, contains(PaymentMedium.appTransfer));
      expect(cashMediums, isNot(contains(PaymentMedium.creditCard)));
    });

    test('requiresSubmedium es correcto', () {
      expect(PaymentMedium.bankTransfer.requiresSubmedium, true);
      expect(PaymentMedium.appTransfer.requiresSubmedium, true);
      expect(PaymentMedium.creditCard.requiresSubmedium, false);
      expect(PaymentMedium.cashMoney.requiresSubmedium, false);
      expect(PaymentMedium.fiado.requiresSubmedium, false);
    });
  });

  group('BankTransferProvider', () {
    test('fromValue devuelve banco correcto', () {
      expect(BankTransferProvider.fromValue('bancolombia'),
          BankTransferProvider.bancolombia);
      expect(BankTransferProvider.fromValue('davivienda'),
          BankTransferProvider.davivienda);
    });

    test('fromValue devuelve otro para valor inválido', () {
      expect(BankTransferProvider.fromValue('banco_falso'),
          BankTransferProvider.otro);
    });

    test('tiene todos los bancos colombianos principales', () {
      final bancos = BankTransferProvider.values.map((b) => b.value).toList();
      expect(bancos, contains('bancolombia'));
      expect(bancos, contains('davivienda'));
      expect(bancos, contains('bbva'));
      expect(bancos, contains('banco_popular'));
    });
  });

  group('AppTransferProvider', () {
    test('fromValue devuelve app correcta', () {
      expect(
          AppTransferProvider.fromValue('nequi'), AppTransferProvider.nequi);
      expect(AppTransferProvider.fromValue('daviplata'),
          AppTransferProvider.daviplata);
    });

    test('tiene apps de pago populares en Colombia', () {
      final apps = AppTransferProvider.values.map((a) => a.value).toList();
      expect(apps, contains('nequi'));
      expect(apps, contains('daviplata'));
      expect(apps, contains('rappipay'));
    });
  });

  group('EstablishmentCategory', () {
    test('fromValue devuelve categoría correcta', () {
      expect(EstablishmentCategory.fromValue('supermercado'),
          EstablishmentCategory.supermercado);
      expect(EstablishmentCategory.fromValue('tienda'),
          EstablishmentCategory.tienda);
    });

    test('fromValue devuelve otro para valor inválido', () {
      expect(EstablishmentCategory.fromValue('categoria_falsa'),
          EstablishmentCategory.otro);
    });

    test('tiene todas las categorías esperadas', () {
      final cats =
          EstablishmentCategory.values.map((c) => c.value).toList();
      expect(cats, contains('supermercado'));
      expect(cats, contains('tienda'));
      expect(cats, contains('restaurante'));
      expect(cats, contains('farmacia'));
      expect(cats, contains('online'));
    });
  });

  group('PaymentSuggestionHelper', () {
    test('sugiere tarjeta de crédito para cuentas de crédito', () {
      final suggestion =
          PaymentSuggestionHelper.suggestFromAccountType('credit', null);
      expect(suggestion.method, PaymentMethod.credit);
      expect(suggestion.medium, PaymentMedium.creditCard);
    });

    test('sugiere efectivo para cuentas de efectivo', () {
      final suggestion =
          PaymentSuggestionHelper.suggestFromAccountType('cash', null);
      expect(suggestion.method, PaymentMethod.cash);
      expect(suggestion.medium, PaymentMedium.cashMoney);
    });

    test('detecta Nequi en nombre de cuenta wallet', () {
      final suggestion = PaymentSuggestionHelper.suggestFromAccountType(
          'wallet', 'Mi Nequi');
      expect(suggestion.method, PaymentMethod.cash);
      expect(suggestion.medium, PaymentMedium.appTransfer);
      expect(suggestion.submedium, 'nequi');
    });

    test('detecta DaviPlata en nombre de cuenta wallet', () {
      final suggestion = PaymentSuggestionHelper.suggestFromAccountType(
          'wallet', 'Daviplata Personal');
      expect(suggestion.submedium, 'daviplata');
    });

    test('detecta Bancolombia en cuenta bancaria', () {
      final suggestion = PaymentSuggestionHelper.suggestFromAccountType(
          'bank', 'Ahorros Bancolombia');
      expect(suggestion.method, PaymentMethod.cash);
      expect(suggestion.medium, PaymentMedium.bankTransfer);
      expect(suggestion.submedium, 'bancolombia');
    });

    test('detecta Davivienda en cuenta de ahorros', () {
      final suggestion = PaymentSuggestionHelper.suggestFromAccountType(
          'savings', 'Cuenta Davivienda');
      expect(suggestion.submedium, 'davivienda');
    });

    test('retorna null para tipos desconocidos', () {
      final suggestion = PaymentSuggestionHelper.suggestFromAccountType(
          'investment', 'Mi inversión');
      expect(suggestion.method, isNull);
      expect(suggestion.medium, isNull);
      expect(suggestion.submedium, isNull);
    });
  });
}
