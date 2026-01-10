// RecurringTransactionService - Lógica de negocio para transacciones recurrentes
// Extraído de recurring_transactions_provider.dart (FASE R6)

import 'package:uuid/uuid.dart';

/// Frecuencias de recurrencia
enum RecurrenceFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  bimonthly,
  quarterly,
  semiannual,
  yearly,
}

/// Interfaz de repositorio para transacciones recurrentes
abstract class RecurringTransactionRepository {
  Future<List<RecurringTransactionData>> getActive();
  Future<List<RecurringTransactionData>> getDueForExecution();
  Future<List<RecurringTransactionData>> getPendingConfirmation();
  Future<RecurringTransactionData?> getById(String id);
  Future<void> insert(RecurringTransactionData data);
  Future<void> update(RecurringTransactionData data);
  Future<void> delete(String id);
  Future<void> activate(String id);
  Future<void> deactivate(String id);
  Future<void> markAsExecuted(String id, DateTime nextDate);
  Future<void> incrementExecutionCount(String id);
  Stream<List<RecurringTransactionData>> watchActive();
  Stream<List<RecurringTransactionData>> watchPendingConfirmation();
}

// ============================================================
// MODELO DE DOMINIO
// ============================================================

/// Datos de transacción recurrente para la capa de dominio
class RecurringTransactionData {
  final String id;
  final String name;
  final String type; // expense, income, transfer
  final double amount;
  final String? description;
  final String? fromAccountId;
  final String? toAccountId;
  final String categoryId;
  final String frequency; // daily, weekly, monthly, etc.
  final int dayOfExecution;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextExecutionDate;
  final DateTime? lastExecutedAt;
  final int executionCount;
  final bool isActive;
  final bool requiresConfirmation;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringTransactionData({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.description,
    this.fromAccountId,
    this.toAccountId,
    required this.categoryId,
    required this.frequency,
    required this.dayOfExecution,
    required this.startDate,
    this.endDate,
    this.nextExecutionDate,
    this.lastExecutedAt,
    this.executionCount = 0,
    this.isActive = true,
    this.requiresConfirmation = false,
    required this.createdAt,
    required this.updatedAt,
  });

  RecurringTransactionData copyWith({
    String? id,
    String? name,
    String? type,
    double? amount,
    String? description,
    String? fromAccountId,
    String? toAccountId,
    String? categoryId,
    String? frequency,
    int? dayOfExecution,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextExecutionDate,
    DateTime? lastExecutedAt,
    int? executionCount,
    bool? isActive,
    bool? requiresConfirmation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransactionData(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      dayOfExecution: dayOfExecution ?? this.dayOfExecution,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      executionCount: executionCount ?? this.executionCount,
      isActive: isActive ?? this.isActive,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  RecurrenceFrequency get frequencyEnum => RecurrenceFrequency.values.firstWhere(
        (f) => f.name == frequency,
        orElse: () => RecurrenceFrequency.monthly,
      );
}

/// Resultado de ejecución de transacciones
class ExecutionResult {
  final int executedCount;
  final int skippedCount;
  final List<String> errors;

  const ExecutionResult({
    required this.executedCount,
    required this.skippedCount,
    this.errors = const [],
  });
}

// ============================================================
// SERVICIO DE DOMINIO
// ============================================================

/// Servicio de dominio para transacciones recurrentes
/// Contiene toda la lógica de negocio, independiente del framework
class RecurringTransactionService {
  final RecurringTransactionRepository repository;

  const RecurringTransactionService({required this.repository});

  /// Crea una nueva transacción recurrente
  Future<String> create({
    required String name,
    required String type,
    required double amount,
    required String categoryId,
    required RecurrenceFrequency frequency,
    required int dayOfExecution,
    required DateTime startDate,
    String? description,
    String? fromAccountId,
    String? toAccountId,
    DateTime? endDate,
    bool requiresConfirmation = false,
  }) async {
    // Validaciones
    if (amount <= 0) {
      throw const RecurringTransactionException('El monto debe ser mayor a cero');
    }

    if (name.trim().isEmpty) {
      throw const RecurringTransactionException('El nombre es requerido');
    }

    final id = const Uuid().v4();
    final now = DateTime.now();

    final nextExecution = calculateNextExecution(
      frequency: frequency,
      dayOfExecution: dayOfExecution,
      fromDate: startDate,
    );

    await repository.insert(RecurringTransactionData(
      id: id,
      name: name.trim(),
      type: type,
      amount: amount,
      description: description,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      frequency: frequency.name,
      dayOfExecution: dayOfExecution,
      startDate: startDate,
      endDate: endDate,
      nextExecutionDate: nextExecution,
      requiresConfirmation: requiresConfirmation,
      createdAt: now,
      updatedAt: now,
    ));

    return id;
  }

  /// Actualiza una transacción recurrente
  Future<void> update({
    required String id,
    String? name,
    double? amount,
    String? description,
    String? categoryId,
    RecurrenceFrequency? frequency,
    int? dayOfExecution,
    DateTime? endDate,
    bool? requiresConfirmation,
  }) async {
    final existing = await repository.getById(id);
    if (existing == null) {
      throw const RecurringTransactionNotFoundException('Transacción recurrente no encontrada');
    }

    // Recalcular próxima ejecución si cambia frecuencia o día
    DateTime? newNextExecution;
    if (frequency != null || dayOfExecution != null) {
      newNextExecution = calculateNextExecution(
        frequency: frequency ?? existing.frequencyEnum,
        dayOfExecution: dayOfExecution ?? existing.dayOfExecution,
        fromDate: DateTime.now(),
      );
    }

    await repository.update(existing.copyWith(
      name: name,
      amount: amount,
      description: description,
      categoryId: categoryId,
      frequency: frequency?.name,
      dayOfExecution: dayOfExecution,
      endDate: endDate,
      nextExecutionDate: newNextExecution,
      requiresConfirmation: requiresConfirmation,
      updatedAt: DateTime.now(),
    ));
  }

  /// Activa una transacción recurrente
  Future<void> activate(String id) async {
    await repository.activate(id);
  }

  /// Desactiva una transacción recurrente
  Future<void> deactivate(String id) async {
    await repository.deactivate(id);
  }

  /// Elimina una transacción recurrente
  Future<void> delete(String id) async {
    await repository.delete(id);
  }

  /// Ejecuta todas las transacciones recurrentes pendientes
  Future<ExecutionResult> executeAllDue() async {
    final dueTransactions = await repository.getDueForExecution();

    var executedCount = 0;
    var skippedCount = 0;
    final errors = <String>[];

    for (final recurring in dueTransactions) {
      try {
        // Solo ejecutar si no requiere confirmación
        if (!recurring.requiresConfirmation) {
          await executeOne(recurring.id);
          executedCount++;
        } else {
          skippedCount++;
        }
      } catch (e) {
        errors.add('Error en ${recurring.name}: $e');
      }
    }

    return ExecutionResult(
      executedCount: executedCount,
      skippedCount: skippedCount,
      errors: errors,
    );
  }

  /// Ejecuta una transacción recurrente específica
  Future<void> executeOne(String id) async {
    final recurring = await repository.getById(id);
    if (recurring == null) {
      throw const RecurringTransactionNotFoundException('Transacción recurrente no encontrada');
    }

    await _executeRecurring(recurring);
  }

  /// Ejecuta la lógica interna de una transacción recurrente
  Future<void> _executeRecurring(RecurringTransactionData recurring) async {
    // Calcular próxima fecha de ejecución
    final nextDate = calculateNextExecution(
      frequency: recurring.frequencyEnum,
      dayOfExecution: recurring.dayOfExecution,
      fromDate: DateTime.now(),
    );

    // Actualizar la transacción recurrente
    await repository.markAsExecuted(recurring.id, nextDate);
    await repository.incrementExecutionCount(recurring.id);

    // Verificar si debe desactivarse (fecha fin alcanzada)
    if (recurring.endDate != null && nextDate.isAfter(recurring.endDate!)) {
      await repository.deactivate(recurring.id);
    }
  }

  /// Calcula la próxima fecha de ejecución
  DateTime calculateNextExecution({
    required RecurrenceFrequency frequency,
    required int dayOfExecution,
    required DateTime fromDate,
  }) {
    final now = DateTime.now();
    var next = fromDate;

    // Si la fecha de inicio ya pasó, calcular desde hoy
    if (next.isBefore(now)) {
      next = now;
    }

    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(next.year, next.month, next.day + 1);

      case RecurrenceFrequency.weekly:
        // dayOfExecution: 1 = Lunes, 7 = Domingo
        var daysUntilNext = dayOfExecution - next.weekday;
        if (daysUntilNext <= 0) daysUntilNext += 7;
        return DateTime(next.year, next.month, next.day + daysUntilNext);

      case RecurrenceFrequency.biweekly:
        var daysUntilNext = dayOfExecution - next.weekday;
        if (daysUntilNext <= 0) daysUntilNext += 14;
        return DateTime(next.year, next.month, next.day + daysUntilNext);

      case RecurrenceFrequency.monthly:
        return _calculateMonthlyNext(next, dayOfExecution, 1);

      case RecurrenceFrequency.bimonthly:
        return _calculateMonthlyNext(next, dayOfExecution, 2);

      case RecurrenceFrequency.quarterly:
        return _calculateMonthlyNext(next, dayOfExecution, 3);

      case RecurrenceFrequency.semiannual:
        return _calculateMonthlyNext(next, dayOfExecution, 6);

      case RecurrenceFrequency.yearly:
        return DateTime(next.year + 1, next.month, dayOfExecution);
    }
  }

  /// Calcula la próxima fecha para frecuencias mensuales
  DateTime _calculateMonthlyNext(DateTime from, int dayOfExecution, int monthsToAdd) {
    var targetMonth = from.month;
    var targetYear = from.year;

    // Si el día actual es >= día de ejecución, avanzar al siguiente período
    if (from.day >= dayOfExecution) {
      targetMonth += monthsToAdd;
    }

    while (targetMonth > 12) {
      targetMonth -= 12;
      targetYear++;
    }

    final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = dayOfExecution > lastDayOfMonth ? lastDayOfMonth : dayOfExecution;

    return DateTime(targetYear, targetMonth, day);
  }

  /// Obtiene el nombre legible de una frecuencia
  static String getFrequencyDisplayName(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Diario';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.biweekly:
        return 'Quincenal';
      case RecurrenceFrequency.monthly:
        return 'Mensual';
      case RecurrenceFrequency.bimonthly:
        return 'Bimestral';
      case RecurrenceFrequency.quarterly:
        return 'Trimestral';
      case RecurrenceFrequency.semiannual:
        return 'Semestral';
      case RecurrenceFrequency.yearly:
        return 'Anual';
    }
  }

  /// Obtiene el día de la semana legible
  static String getDayOfWeekName(int day) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    if (day < 1 || day > 7) return 'Día $day';
    return days[day - 1];
  }
}

// ============================================================
// EXCEPCIONES DE DOMINIO
// ============================================================

class RecurringTransactionException implements Exception {
  final String message;
  const RecurringTransactionException(this.message);
  @override
  String toString() => message;
}

class RecurringTransactionNotFoundException extends RecurringTransactionException {
  const RecurringTransactionNotFoundException(super.message);
}
