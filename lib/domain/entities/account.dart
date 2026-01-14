import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// Entidad de Cuenta inmutable
/// Representa una cuenta financiera (activo o pasivo)
@freezed
class Account with _$Account {
  const Account._();

  const factory Account({
    required String id,
    required String name,
    required String categoryId,
    @Default(0.0) double balance,
    String? currency,
    String? institution,
    String? accountNumber,
    String? notes,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  /// Verifica si el saldo es positivo
  bool get hasPositiveBalance => balance > 0;

  /// Verifica si el saldo es negativo (deuda)
  bool get hasNegativeBalance => balance < 0;

  /// Formatea el saldo como moneda (sin locale específico)
  String get formattedBalance {
    final absBalance = balance.abs();
    final sign = balance < 0 ? '-' : '';
    return '$sign\$${absBalance.toStringAsFixed(0)}';
  }
}
