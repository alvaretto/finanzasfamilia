import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/payment_methods_table.dart';

part 'payment_methods_dao.g.dart';

/// DAO para operaciones con métodos de pago
@DriftAccessor(tables: [PaymentMethods])
class PaymentMethodsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentMethodsDaoMixin {
  PaymentMethodsDao(super.db);

  /// Obtiene todos los métodos de pago activos
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<PaymentMethodEntry>> getAllActiveMethods() {
    return (select(paymentMethods)
          ..where((pm) => pm.isActive.equals(true) | pm.isActive.isNull())
          ..orderBy([
            (pm) => OrderingTerm.desc(pm.isDefault),
            (pm) => OrderingTerm.asc(pm.sortOrder),
            (pm) => OrderingTerm.asc(pm.name),
          ]))
        .get();
  }

  /// Obtiene todos los métodos de pago
  Future<List<PaymentMethodEntry>> getAllMethods() {
    return (select(paymentMethods)
          ..orderBy([
            (pm) => OrderingTerm.desc(pm.isDefault),
            (pm) => OrderingTerm.asc(pm.sortOrder),
          ]))
        .get();
  }

  /// Obtiene el método de pago por defecto
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<PaymentMethodEntry?> getDefaultMethod() {
    return (select(paymentMethods)
          ..where((pm) => pm.isDefault.equals(true))
          ..where((pm) => pm.isActive.equals(true) | pm.isActive.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  /// Obtiene un método de pago por ID
  Future<PaymentMethodEntry?> getMethodById(String id) {
    return (select(paymentMethods)..where((pm) => pm.id.equals(id)))
        .getSingleOrNull();
  }

  /// Obtiene métodos de pago por cuenta asociada
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<PaymentMethodEntry>> getMethodsByAccount(String accountId) {
    return (select(paymentMethods)
          ..where((pm) => pm.accountId.equals(accountId))
          ..where((pm) => pm.isActive.equals(true) | pm.isActive.isNull()))
        .get();
  }

  /// Inserta un nuevo método de pago
  Future<void> insertMethod(PaymentMethodsCompanion method) {
    return into(paymentMethods).insert(method);
  }

  /// Inserta múltiples métodos de pago
  Future<void> insertMethods(List<PaymentMethodsCompanion> methods) {
    return batch((batch) {
      batch.insertAll(paymentMethods, methods);
    });
  }

  /// Actualiza un método de pago
  Future<bool> updateMethod(PaymentMethodEntry method) {
    return update(paymentMethods).replace(method);
  }

  /// Establece un método como el predeterminado
  Future<void> setAsDefault(String id) async {
    // Primero, quitar el default de todos
    await (update(paymentMethods))
        .write(const PaymentMethodsCompanion(isDefault: Value(false)));

    // Luego, establecer el nuevo default
    await (update(paymentMethods)..where((pm) => pm.id.equals(id)))
        .write(const PaymentMethodsCompanion(isDefault: Value(true)));
  }

  /// Elimina un método de pago (soft delete)
  Future<int> deactivateMethod(String id) {
    return (update(paymentMethods)..where((pm) => pm.id.equals(id)))
        .write(const PaymentMethodsCompanion(isActive: Value(false)));
  }
}
