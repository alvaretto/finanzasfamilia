import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/account_form_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('accountIconProvider', () {
    test('valor inicial es 💰', () {
      final container = ProviderContainer();
      expect(container.read(accountIconProvider), equals('💰'));
      container.dispose();
    });

    test('puede cambiar icono', () {
      final container = ProviderContainer();

      container.read(accountIconProvider.notifier).state = '💳';
      expect(container.read(accountIconProvider), equals('💳'));

      container.read(accountIconProvider.notifier).state = '🏦';
      expect(container.read(accountIconProvider), equals('🏦'));

      container.dispose();
    });
  });

  group('accountColorProvider', () {
    test('valor inicial es #4CAF50', () {
      final container = ProviderContainer();
      expect(container.read(accountColorProvider), equals('#4CAF50'));
      container.dispose();
    });

    test('puede cambiar color', () {
      final container = ProviderContainer();

      container.read(accountColorProvider.notifier).state = '#2196F3';
      expect(container.read(accountColorProvider), equals('#2196F3'));

      container.read(accountColorProvider.notifier).state = '#F44336';
      expect(container.read(accountColorProvider), equals('#F44336'));

      container.dispose();
    });
  });

  group('includeInTotalProvider', () {
    test('valor inicial es true', () {
      final container = ProviderContainer();
      expect(container.read(includeInTotalProvider), isTrue);
      container.dispose();
    });

    test('puede cambiar valor', () {
      final container = ProviderContainer();

      container.read(includeInTotalProvider.notifier).state = false;
      expect(container.read(includeInTotalProvider), isFalse);

      container.read(includeInTotalProvider.notifier).state = true;
      expect(container.read(includeInTotalProvider), isTrue);

      container.dispose();
    });
  });

  group('accountCategoryIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(accountCategoryIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar categoría', () {
      final container = ProviderContainer();

      container.read(accountCategoryIdProvider.notifier).state = 'cat-asset-123';
      expect(container.read(accountCategoryIdProvider), equals('cat-asset-123'));

      container.dispose();
    });
  });
}
