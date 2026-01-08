import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/category_form_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('formCategoryTypeProvider', () {
    test('valor inicial es expense', () {
      final container = ProviderContainer();
      expect(container.read(formCategoryTypeProvider), equals('expense'));
      container.dispose();
    });

    test('puede cambiar tipo', () {
      final container = ProviderContainer();

      container.read(formCategoryTypeProvider.notifier).state = 'income';
      expect(container.read(formCategoryTypeProvider), equals('income'));

      container.read(formCategoryTypeProvider.notifier).state = 'asset';
      expect(container.read(formCategoryTypeProvider), equals('asset'));

      container.read(formCategoryTypeProvider.notifier).state = 'liability';
      expect(container.read(formCategoryTypeProvider), equals('liability'));

      container.dispose();
    });
  });

  group('selectedIconProvider', () {
    test('valor inicial es 📁', () {
      final container = ProviderContainer();
      expect(container.read(selectedIconProvider), equals('📁'));
      container.dispose();
    });

    test('puede cambiar icono', () {
      final container = ProviderContainer();

      container.read(selectedIconProvider.notifier).state = '🏠';
      expect(container.read(selectedIconProvider), equals('🏠'));

      container.read(selectedIconProvider.notifier).state = '🍔';
      expect(container.read(selectedIconProvider), equals('🍔'));

      container.dispose();
    });
  });

  group('selectedParentIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(selectedParentIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar padre', () {
      final container = ProviderContainer();

      container.read(selectedParentIdProvider.notifier).state = 'parent-123';
      expect(container.read(selectedParentIdProvider), equals('parent-123'));

      container.read(selectedParentIdProvider.notifier).state = null;
      expect(container.read(selectedParentIdProvider), isNull);

      container.dispose();
    });
  });
}
