import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/transaction_form_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('transactionTypeProvider', () {
    test('valor inicial es expense', () {
      final container = ProviderContainer();
      expect(container.read(transactionTypeProvider), equals('expense'));
      container.dispose();
    });

    test('puede cambiar tipo', () {
      final container = ProviderContainer();

      container.read(transactionTypeProvider.notifier).state = 'income';
      expect(container.read(transactionTypeProvider), equals('income'));

      container.read(transactionTypeProvider.notifier).state = 'transfer';
      expect(container.read(transactionTypeProvider), equals('transfer'));

      container.dispose();
    });
  });

  group('selectedDateProvider', () {
    test('valor inicial es hoy', () {
      final container = ProviderContainer();
      final today = DateTime.now();
      final selected = container.read(selectedDateProvider);

      expect(selected.year, equals(today.year));
      expect(selected.month, equals(today.month));
      expect(selected.day, equals(today.day));

      container.dispose();
    });

    test('puede cambiar fecha', () {
      final container = ProviderContainer();
      final newDate = DateTime(2024, 6, 15);

      container.read(selectedDateProvider.notifier).state = newDate;
      expect(container.read(selectedDateProvider), equals(newDate));

      container.dispose();
    });
  });

  group('selectedCategoryIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(selectedCategoryIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar categoría', () {
      final container = ProviderContainer();

      container.read(selectedCategoryIdProvider.notifier).state = 'cat-123';
      expect(container.read(selectedCategoryIdProvider), equals('cat-123'));

      container.dispose();
    });
  });

  group('selectedFromAccountIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(selectedFromAccountIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar cuenta origen', () {
      final container = ProviderContainer();

      container.read(selectedFromAccountIdProvider.notifier).state = 'acc-123';
      expect(container.read(selectedFromAccountIdProvider), equals('acc-123'));

      container.dispose();
    });
  });

  group('selectedToAccountIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(selectedToAccountIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar cuenta destino', () {
      final container = ProviderContainer();

      container.read(selectedToAccountIdProvider.notifier).state = 'acc-456';
      expect(container.read(selectedToAccountIdProvider), equals('acc-456'));

      container.dispose();
    });
  });
}
