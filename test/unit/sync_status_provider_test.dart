import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/providers/sync_status_provider.dart';

/// Tests para el SyncStatusProvider
/// Gestiona el estado de sincronización de PowerSync
void main() {
  group('SyncState', () {
    test('crea estado inicial desconectado', () {
      // Act
      const state = SyncState();

      // Assert
      expect(state.isConnected, isFalse);
      expect(state.isDownloading, isFalse);
      expect(state.isUploading, isFalse);
      expect(state.isSyncing, isFalse);
      expect(state.lastSyncTime, isNull);
      expect(state.errors, isEmpty);
    });

    test('crea estado conectado', () {
      // Act
      const state = SyncState(isConnected: true);

      // Assert
      expect(state.isConnected, isTrue);
      expect(state.isSyncing, isFalse);
    });

    test('detecta sincronización activa con downloading', () {
      // Act
      const state = SyncState(isConnected: true, isDownloading: true);

      // Assert
      expect(state.isSyncing, isTrue);
    });

    test('detecta sincronización activa con uploading', () {
      // Act
      const state = SyncState(isConnected: true, isUploading: true);

      // Assert
      expect(state.isSyncing, isTrue);
    });

    test('copyWith crea nueva instancia con valores actualizados', () {
      // Arrange
      const original = SyncState();

      // Act
      final updated = original.copyWith(
        isConnected: true,
        isDownloading: true,
        lastSyncTime: DateTime(2024, 6, 15),
      );

      // Assert
      expect(updated.isConnected, isTrue);
      expect(updated.isDownloading, isTrue);
      expect(updated.lastSyncTime, equals(DateTime(2024, 6, 15)));
      expect(original.isConnected, isFalse); // Original no cambia
    });

    test('copyWith preserva valores no especificados', () {
      // Arrange
      const original = SyncState(
        isConnected: true,
        errors: ['Error 1'],
      );

      // Act
      final updated = original.copyWith(isDownloading: true);

      // Assert
      expect(updated.isConnected, isTrue); // Preservado
      expect(updated.errors, equals(['Error 1'])); // Preservado
      expect(updated.isDownloading, isTrue); // Actualizado
    });
  });

  group('SyncStatusNotifier', () {
    test('estado inicial es desconectado', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final state = container.read(syncStatusProvider);

      // Assert
      expect(state.isConnected, isFalse);
    });

    test('updateStatus actualiza el estado', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container.read(syncStatusProvider.notifier).updateStatus(
            isConnected: true,
            isDownloading: true,
          );

      // Assert
      final state = container.read(syncStatusProvider);
      expect(state.isConnected, isTrue);
      expect(state.isDownloading, isTrue);
    });

    test('markSynced actualiza lastSyncTime', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container.read(syncStatusProvider.notifier).markSynced();

      // Assert
      final state = container.read(syncStatusProvider);
      expect(state.lastSyncTime, isNotNull);
      expect(
        state.lastSyncTime!.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('addError agrega error a la lista', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container.read(syncStatusProvider.notifier).addError('Error de sync');

      // Assert
      final state = container.read(syncStatusProvider);
      expect(state.errors, contains('Error de sync'));
    });

    test('clearErrors limpia la lista de errores', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(syncStatusProvider.notifier).addError('Error 1');
      container.read(syncStatusProvider.notifier).addError('Error 2');

      // Act
      container.read(syncStatusProvider.notifier).clearErrors();

      // Assert
      final state = container.read(syncStatusProvider);
      expect(state.errors, isEmpty);
    });

    test('setOfflineMode establece estado offline', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(syncStatusProvider.notifier).updateStatus(
            isConnected: true,
            isDownloading: true,
          );

      // Act
      container.read(syncStatusProvider.notifier).setOfflineMode();

      // Assert
      final state = container.read(syncStatusProvider);
      expect(state.isConnected, isFalse);
      expect(state.isDownloading, isFalse);
      expect(state.isUploading, isFalse);
    });
  });

  group('Providers Derivados', () {
    test('isConnectedProvider refleja estado de conexión', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act & Assert - inicialmente desconectado
      expect(container.read(isConnectedProvider), isFalse);

      // Conectar
      container.read(syncStatusProvider.notifier).updateStatus(isConnected: true);
      expect(container.read(isConnectedProvider), isTrue);
    });

    test('isSyncingProvider refleja estado de sincronización', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act & Assert - inicialmente no sincronizando
      expect(container.read(isSyncingProvider), isFalse);

      // Iniciar descarga
      container.read(syncStatusProvider.notifier).updateStatus(
            isConnected: true,
            isDownloading: true,
          );
      expect(container.read(isSyncingProvider), isTrue);
    });

    test('syncErrorsProvider refleja errores', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act & Assert - inicialmente sin errores
      expect(container.read(syncErrorsProvider), isEmpty);

      // Agregar error
      container.read(syncStatusProvider.notifier).addError('Test error');
      expect(container.read(syncErrorsProvider), contains('Test error'));
    });

    test('lastSyncTimeProvider refleja última sincronización', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act & Assert - inicialmente null
      expect(container.read(lastSyncTimeProvider), isNull);

      // Marcar como sincronizado
      container.read(syncStatusProvider.notifier).markSynced();
      expect(container.read(lastSyncTimeProvider), isNotNull);
    });
  });
}
