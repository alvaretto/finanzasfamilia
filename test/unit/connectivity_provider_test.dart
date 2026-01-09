import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/application/providers/connectivity_provider.dart';

void main() {
  // Asegurar que el binding esté inicializado para tests que usan platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityStatus', () {
    test('tiene 3 estados: online, offline, checking', () {
      expect(ConnectivityStatus.values.length, equals(3));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.online));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.offline));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.checking));
    });
  });

  group('ConnectivityNotifier', () {
    test('estado inicial es checking', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final status = container.read(connectivityNotifierProvider);
      expect(status, equals(ConnectivityStatus.checking));
    });
  });

  group('isOnline provider', () {
    test('retorna false cuando estado es offline', () {
      final container = ProviderContainer(
        overrides: [
          connectivityNotifierProvider.overrideWith(() {
            return _MockConnectivityNotifier(ConnectivityStatus.offline);
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isOnlineProvider), isFalse);
    });

    test('retorna true cuando estado es online', () {
      final container = ProviderContainer(
        overrides: [
          connectivityNotifierProvider.overrideWith(() {
            return _MockConnectivityNotifier(ConnectivityStatus.online);
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isOnlineProvider), isTrue);
    });

    test('retorna false cuando estado es checking', () {
      final container = ProviderContainer(
        overrides: [
          connectivityNotifierProvider.overrideWith(() {
            return _MockConnectivityNotifier(ConnectivityStatus.checking);
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isOnlineProvider), isFalse);
    });
  });

  group('isCheckingConnectivity provider', () {
    test('retorna true cuando estado es checking', () {
      final container = ProviderContainer(
        overrides: [
          connectivityNotifierProvider.overrideWith(() {
            return _MockConnectivityNotifier(ConnectivityStatus.checking);
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isCheckingConnectivityProvider), isTrue);
    });

    test('retorna false cuando estado es online', () {
      final container = ProviderContainer(
        overrides: [
          connectivityNotifierProvider.overrideWith(() {
            return _MockConnectivityNotifier(ConnectivityStatus.online);
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isCheckingConnectivityProvider), isFalse);
    });
  });
}

/// Mock del ConnectivityNotifier para tests
class _MockConnectivityNotifier extends ConnectivityNotifier {
  final ConnectivityStatus _status;

  _MockConnectivityNotifier(this._status);

  @override
  ConnectivityStatus build() => _status;
}
