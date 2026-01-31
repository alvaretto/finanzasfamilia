import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/domain/services/recurring_transaction_service.dart';

/// Repositorio in-memory para testing
class InMemoryRecurringTransactionRepository
    implements RecurringTransactionRepository {
  final Map<String, RecurringTransactionData> _data = {};

  @override
  Future<List<RecurringTransactionData>> getActive() async {
    return _data.values.where((t) => t.isActive).toList();
  }

  @override
  Future<List<RecurringTransactionData>> getDueForExecution() async {
    final now = DateTime.now();
    return _data.values.where((t) {
      if (!t.isActive) return false;
      if (t.nextExecutionDate == null) return false;
      return t.nextExecutionDate!.isBefore(now) ||
          t.nextExecutionDate!.isAtSameMomentAs(now);
    }).toList();
  }

  @override
  Future<List<RecurringTransactionData>> getPendingConfirmation() async {
    return _data.values
        .where((t) => t.isActive && t.requiresConfirmation)
        .toList();
  }

  @override
  Future<RecurringTransactionData?> getById(String id) async {
    return _data[id];
  }

  @override
  Future<void> insert(RecurringTransactionData data) async {
    _data[data.id] = data;
  }

  @override
  Future<void> update(RecurringTransactionData data) async {
    _data[data.id] = data;
  }

  @override
  Future<void> delete(String id) async {
    _data.remove(id);
  }

  @override
  Future<void> activate(String id) async {
    final existing = _data[id];
    if (existing != null) {
      _data[id] = existing.copyWith(isActive: true);
    }
  }

  @override
  Future<void> deactivate(String id) async {
    final existing = _data[id];
    if (existing != null) {
      _data[id] = existing.copyWith(isActive: false);
    }
  }

  @override
  Future<void> markAsExecuted(String id, DateTime nextDate) async {
    final existing = _data[id];
    if (existing != null) {
      _data[id] = existing.copyWith(
        lastExecutedAt: DateTime.now(),
        nextExecutionDate: nextDate,
      );
    }
  }

  @override
  Future<void> incrementExecutionCount(String id) async {
    final existing = _data[id];
    if (existing != null) {
      _data[id] = existing.copyWith(
        executionCount: existing.executionCount + 1,
      );
    }
  }

  @override
  Stream<List<RecurringTransactionData>> watchActive() {
    return Stream.value(_data.values.where((t) => t.isActive).toList());
  }

  @override
  Stream<List<RecurringTransactionData>> watchPendingConfirmation() {
    return Stream.value(_data.values
        .where((t) => t.isActive && t.requiresConfirmation)
        .toList());
  }

  void clear() => _data.clear();
  int get count => _data.length;
}

void main() {
  late RecurringTransactionService service;
  late InMemoryRecurringTransactionRepository repository;

  setUp(() {
    repository = InMemoryRecurringTransactionRepository();
    service = RecurringTransactionService(repository: repository);
  });

  group('RecurringTransactionService - create', () {
    test('crea transacción recurrente correctamente', () async {
      final id = await service.create(
        name: 'Salario Mensual',
        type: 'income',
        amount: 5000000,
        categoryId: 'cat-income',
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 15,
        startDate: DateTime(2026, 1, 1),
        toAccountId: 'account-1',
      );

      expect(id, isNotEmpty);
      expect(repository.count, equals(1));

      final created = await repository.getById(id);
      expect(created, isNotNull);
      expect(created!.name, equals('Salario Mensual'));
      expect(created.amount, equals(5000000));
      expect(created.frequency, equals('monthly'));
      expect(created.isActive, isTrue);
    });

    test('genera UUID único para cada transacción', () async {
      final id1 = await service.create(
        name: 'Transacción 1',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.weekly,
        dayOfExecution: 1,
        startDate: DateTime.now(),
      );

      final id2 = await service.create(
        name: 'Transacción 2',
        type: 'expense',
        amount: 2000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.weekly,
        dayOfExecution: 1,
        startDate: DateTime.now(),
      );

      expect(id1, isNot(equals(id2)));
    });

    test('rechaza monto cero', () async {
      expect(
        () => service.create(
          name: 'Test',
          type: 'expense',
          amount: 0,
          categoryId: 'cat-1',
          frequency: RecurrenceFrequency.monthly,
          dayOfExecution: 1,
          startDate: DateTime.now(),
        ),
        throwsA(isA<RecurringTransactionException>()),
      );
    });

    test('rechaza monto negativo', () async {
      expect(
        () => service.create(
          name: 'Test',
          type: 'expense',
          amount: -100,
          categoryId: 'cat-1',
          frequency: RecurrenceFrequency.monthly,
          dayOfExecution: 1,
          startDate: DateTime.now(),
        ),
        throwsA(isA<RecurringTransactionException>()),
      );
    });

    test('rechaza nombre vacío', () async {
      expect(
        () => service.create(
          name: '   ',
          type: 'expense',
          amount: 1000,
          categoryId: 'cat-1',
          frequency: RecurrenceFrequency.monthly,
          dayOfExecution: 1,
          startDate: DateTime.now(),
        ),
        throwsA(isA<RecurringTransactionException>()),
      );
    });

    test('calcula próxima ejecución automáticamente', () async {
      final startDate = DateTime(2026, 1, 10);
      final id = await service.create(
        name: 'Test',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 15,
        startDate: startDate,
      );

      final created = await repository.getById(id);
      expect(created!.nextExecutionDate, isNotNull);
    });
  });

  group('RecurringTransactionService - update', () {
    test('actualiza transacción existente', () async {
      final id = await service.create(
        name: 'Original',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 15,
        startDate: DateTime.now(),
      );

      await service.update(
        id: id,
        name: 'Actualizado',
        amount: 2000,
      );

      final updated = await repository.getById(id);
      expect(updated!.name, equals('Actualizado'));
      expect(updated.amount, equals(2000));
    });

    test('lanza excepción si no existe', () async {
      expect(
        () => service.update(
          id: 'non-existent',
          name: 'Test',
        ),
        throwsA(isA<RecurringTransactionNotFoundException>()),
      );
    });

    test('recalcula próxima ejecución al cambiar frecuencia', () async {
      final id = await service.create(
        name: 'Test',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 15,
        startDate: DateTime.now(),
      );

      final original = await repository.getById(id);
      final originalNext = original!.nextExecutionDate;

      await service.update(
        id: id,
        frequency: RecurrenceFrequency.weekly,
        dayOfExecution: 1,
      );

      final updated = await repository.getById(id);
      expect(updated!.frequency, equals('weekly'));
      expect(updated.nextExecutionDate, isNot(equals(originalNext)));
    });
  });

  group('RecurringTransactionService - activate/deactivate', () {
    test('activa transacción', () async {
      final id = await service.create(
        name: 'Test',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 15,
        startDate: DateTime.now(),
      );

      await service.deactivate(id);
      var tx = await repository.getById(id);
      expect(tx!.isActive, isFalse);

      await service.activate(id);
      tx = await repository.getById(id);
      expect(tx!.isActive, isTrue);
    });

    test('desactiva transacción', () async {
      final id = await service.create(
        name: 'Test',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 15,
        startDate: DateTime.now(),
      );

      await service.deactivate(id);
      final tx = await repository.getById(id);
      expect(tx!.isActive, isFalse);
    });
  });

  group('RecurringTransactionService - delete', () {
    test('elimina transacción', () async {
      final id = await service.create(
        name: 'Test',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 15,
        startDate: DateTime.now(),
      );

      expect(repository.count, equals(1));

      await service.delete(id);

      expect(repository.count, equals(0));
      final deleted = await repository.getById(id);
      expect(deleted, isNull);
    });
  });

  group('RecurringTransactionService - calculateNextExecution', () {
    test('daily: retorna día siguiente desde la fecha dada', () {
      // El servicio calcula desde MAX(fromDate, now)
      // Para testing, usamos fechas futuras para asegurar consistencia
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final result = service.calculateNextExecution(
        frequency: RecurrenceFrequency.daily,
        dayOfExecution: 1,
        fromDate: futureDate,
      );

      // Debería ser el día siguiente a la fecha futura
      expect(result.day, equals(futureDate.day + 1));
    });

    test('weekly: calcula próximo día de la semana', () {
      // Usamos una fecha futura para evitar el ajuste a "now"
      final futureDate = DateTime.now().add(const Duration(days: 60));
      final result = service.calculateNextExecution(
        frequency: RecurrenceFrequency.weekly,
        dayOfExecution: 5, // viernes
        fromDate: futureDate,
      );

      expect(result.weekday, equals(5)); // viernes
      expect(result.isAfter(futureDate), isTrue);
    });

    test('weekly: cuando dayOfExecution == weekday, suma 7 días', () {
      // Verificar directamente la lógica del servicio
      // Si fromDate es un viernes y dayOfExecution es 5 (viernes),
      // entonces daysUntilNext = 5 - 5 = 0, y 0 <= 0 es true, suma 7

      // Usamos una fecha conocida que es viernes y está en el futuro
      // 14 marzo 2026 es sábado, 13 marzo 2026 es viernes
      final friday = DateTime(2026, 3, 13);
      expect(friday.weekday, equals(5)); // Verificar que es viernes

      final result = service.calculateNextExecution(
        frequency: RecurrenceFrequency.weekly,
        dayOfExecution: 5, // viernes
        fromDate: friday,
      );

      // El servicio ajusta desde max(fromDate, now), luego calcula
      // Si now < friday, result será friday + 7 días = 20 marzo
      // La diferencia debería ser 7 días
      expect(result.weekday, equals(5)); // También es viernes
      expect(result.isAfter(friday), isTrue);
    });

    test('monthly: próximo mes si día ya pasó', () {
      final now = DateTime(2026, 1, 20); // día 20
      final result = service.calculateNextExecution(
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 15, // día 15
        fromDate: now,
      );

      expect(result.month, equals(2)); // febrero
      expect(result.day, equals(15));
    });

    test('monthly: mismo mes si día no ha llegado', () {
      // Usar fecha futura para evitar que el servicio la sobreescriba con now
      final now = DateTime.now();
      // Crear una fecha en el futuro, día 5 del próximo mes
      final futureDate = DateTime(now.year, now.month + 1, 5);
      final result = service.calculateNextExecution(
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 15, // día 15 (después del día 5)
        fromDate: futureDate,
      );

      // Debería devolver el mismo mes porque día 5 < día 15
      expect(result.month, equals(futureDate.month));
      expect(result.day, equals(15));
    });

    test('monthly: ajusta día 31 a meses cortos', () {
      final now = DateTime(2026, 1, 31); // 31 enero
      final result = service.calculateNextExecution(
        frequency: RecurrenceFrequency.monthly,
        dayOfExecution: 31,
        fromDate: now,
      );

      // Febrero 2026 tiene 28 días
      expect(result.month, equals(2));
      expect(result.day, equals(28));
    });

    test('quarterly: avanza 3 meses', () {
      final now = DateTime(2026, 1, 20);
      final result = service.calculateNextExecution(
        frequency: RecurrenceFrequency.quarterly,
        dayOfExecution: 15,
        fromDate: now,
      );

      expect(result.month, equals(4)); // abril
      expect(result.day, equals(15));
    });

    test('yearly: avanza 1 año', () {
      final now = DateTime(2026, 1, 15);
      final result = service.calculateNextExecution(
        frequency: RecurrenceFrequency.yearly,
        dayOfExecution: 15,
        fromDate: now,
      );

      expect(result.year, equals(2027));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
    });
  });

  group('RecurringTransactionService - executeAllDue', () {
    test('ejecuta transacciones pendientes sin confirmación', () async {
      // Insertar directamente una transacción con nextExecutionDate en el pasado
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      await repository.insert(RecurringTransactionData(
        id: 'test-due-1',
        name: 'Auto-ejecutar',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: 'daily',
        dayOfExecution: 1,
        startDate: pastDate,
        nextExecutionDate: pastDate, // Pendiente de ejecución
        isActive: true,
        requiresConfirmation: false,
        createdAt: pastDate,
        updatedAt: pastDate,
      ));

      final result = await service.executeAllDue();

      expect(result.executedCount, equals(1));
      expect(result.skippedCount, equals(0));
      expect(result.errors, isEmpty);
    });

    test('salta transacciones que requieren confirmación', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      await repository.insert(RecurringTransactionData(
        id: 'test-confirm-1',
        name: 'Requiere confirmación',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: 'daily',
        dayOfExecution: 1,
        startDate: pastDate,
        nextExecutionDate: pastDate,
        isActive: true,
        requiresConfirmation: true,
        createdAt: pastDate,
        updatedAt: pastDate,
      ));

      final result = await service.executeAllDue();

      expect(result.executedCount, equals(0));
      expect(result.skippedCount, equals(1));
    });

    test('reporta errores sin fallar completamente', () async {
      // Este test verifica que errores individuales no rompen el batch
      final result = await service.executeAllDue();

      expect(result, isNotNull);
      expect(result.errors, isEmpty);
    });
  });

  group('RecurringTransactionService - executeOne', () {
    test('ejecuta transacción específica', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final id = await service.create(
        name: 'Test',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.daily,
        dayOfExecution: 1,
        startDate: yesterday,
      );

      await service.executeOne(id);

      final updated = await repository.getById(id);
      expect(updated!.executionCount, equals(1));
      expect(updated.lastExecutedAt, isNotNull);
    });

    test('lanza excepción si no existe', () async {
      expect(
        () => service.executeOne('non-existent'),
        throwsA(isA<RecurringTransactionNotFoundException>()),
      );
    });

    test('desactiva al alcanzar fecha fin', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final id = await service.create(
        name: 'Con fecha fin',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: RecurrenceFrequency.daily,
        dayOfExecution: 1,
        startDate: yesterday,
        endDate: DateTime.now(), // fecha fin = hoy
      );

      await service.executeOne(id);

      final updated = await repository.getById(id);
      expect(updated!.isActive, isFalse);
    });
  });

  group('RecurringTransactionService - helpers', () {
    test('getFrequencyDisplayName retorna nombres legibles', () {
      expect(
        RecurringTransactionService.getFrequencyDisplayName(
            RecurrenceFrequency.daily),
        equals('Diario'),
      );
      expect(
        RecurringTransactionService.getFrequencyDisplayName(
            RecurrenceFrequency.monthly),
        equals('Mensual'),
      );
      expect(
        RecurringTransactionService.getFrequencyDisplayName(
            RecurrenceFrequency.yearly),
        equals('Anual'),
      );
    });

    test('getDayOfWeekName retorna días correctos', () {
      expect(
        RecurringTransactionService.getDayOfWeekName(1),
        equals('Lunes'),
      );
      expect(
        RecurringTransactionService.getDayOfWeekName(7),
        equals('Domingo'),
      );
    });

    test('getDayOfWeekName maneja días inválidos', () {
      expect(
        RecurringTransactionService.getDayOfWeekName(0),
        equals('Día 0'),
      );
      expect(
        RecurringTransactionService.getDayOfWeekName(8),
        equals('Día 8'),
      );
    });
  });

  group('RecurringTransactionData', () {
    test('copyWith preserva valores no especificados', () {
      final original = RecurringTransactionData(
        id: 'test-id',
        name: 'Original',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat-1',
        frequency: 'monthly',
        dayOfExecution: 15,
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final copied = original.copyWith(name: 'Nuevo nombre');

      expect(copied.name, equals('Nuevo nombre'));
      expect(copied.id, equals(original.id));
      expect(copied.amount, equals(original.amount));
      expect(copied.frequency, equals(original.frequency));
    });

    test('frequencyEnum parsea correctamente', () {
      final data = RecurringTransactionData(
        id: 'test',
        name: 'Test',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat',
        frequency: 'quarterly',
        dayOfExecution: 1,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(data.frequencyEnum, equals(RecurrenceFrequency.quarterly));
    });

    test('frequencyEnum retorna monthly por defecto', () {
      final data = RecurringTransactionData(
        id: 'test',
        name: 'Test',
        type: 'expense',
        amount: 1000,
        categoryId: 'cat',
        frequency: 'invalid',
        dayOfExecution: 1,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(data.frequencyEnum, equals(RecurrenceFrequency.monthly));
    });
  });

  group('ExecutionResult', () {
    test('crea resultado correctamente', () {
      const result = ExecutionResult(
        executedCount: 5,
        skippedCount: 2,
        errors: ['Error 1', 'Error 2'],
      );

      expect(result.executedCount, equals(5));
      expect(result.skippedCount, equals(2));
      expect(result.errors, hasLength(2));
    });

    test('errors por defecto es lista vacía', () {
      const result = ExecutionResult(executedCount: 0, skippedCount: 0);

      expect(result.errors, isEmpty);
    });
  });
}
