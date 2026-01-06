# Flujos de Transacciones

Documentación de los flujos de selección de cuenta predeterminada para cada tipo de transacción.

## Problema Original

Al abrir el formulario de transacciones, "Préstamos" aparecía como cuenta predeterminada
para todos los tipos (Gasto, Ingreso, Transferencia), lo cual no es lógico ya que:

- Para **Gastos**: El dinero sale de cuentas donde normalmente tenemos fondos (banco, efectivo)
- Para **Ingresos**: El dinero entra a cuentas donde recibimos pagos (banco, wallet)
- Para **Transferencias**: El origen típicamente es una cuenta líquida

## Solución

### DefaultAccountSelector

Ubicación: `lib/features/transactions/presentation/helpers/default_account_selector.dart`

```dart
DefaultAccountSelector.selectDefaultAccount(
  accounts: accounts,
  transactionType: TransactionType.expense, // o income, transfer
);
```

### Flujo por Tipo de Transacción

#### GASTO (expense)
El dinero **SALE** de una cuenta.

**Prioridad de selección:**
1. `bank` - Cuenta bancaria
2. `wallet` - Billetera digital (Nequi, Daviplata)
3. `cash` - Efectivo
4. `savings` - Ahorros
5. `investment` - Inversiones
6. `receivable` - Cuentas por cobrar
7. `credit` - Tarjeta de crédito (si solo hay pasivos)
8. `loan` - Préstamo (último recurso)
9. `payable` - Cuentas por pagar

**Ejemplo típico:** Usuario paga compra del supermercado → Cuenta bancaria predeterminada

#### INGRESO (income)
El dinero **ENTRA** a una cuenta.

**Prioridad de selección:**
1. `bank` - Cuenta bancaria
2. `wallet` - Billetera digital
3. `cash` - Efectivo
4. `savings` - Ahorros
5. Otros activos

**Ejemplo típico:** Usuario recibe salario → Cuenta bancaria predeterminada

#### TRANSFERENCIA (transfer)
El dinero se **MUEVE** entre cuentas.

**Cuenta origen:**
- Prioridad: Activos líquidos (bank > wallet > cash > savings)
- No se selecciona préstamo como origen por defecto

**Cuenta destino:**
- Cualquier cuenta diferente al origen
- Puede incluir pasivos (ej: pagar tarjeta de crédito)

**Ejemplo típico:** Usuario paga tarjeta de crédito → Origen: Banco, Destino: Tarjeta

## Comportamiento al Cambiar Tipo

Cuando el usuario cambia el tipo de transacción en el formulario:

1. Se **reselecciona** la cuenta predeterminada según el nuevo tipo
2. Se limpia la categoría seleccionada
3. Se limpia la cuenta de transferencia (si ya no es transferencia)

```dart
onSelectionChanged: (selection) {
  final newType = selection.first;
  final accounts = ref.read(activeAccountsProvider);
  setState(() {
    _selectedType = newType;
    _selectedCategoryId = null;
    _selectedAccountId = DefaultAccountSelector.selectDefaultAccount(
      accounts: accounts,
      transactionType: newType,
    );
    if (newType != TransactionType.transfer) {
      _selectedTransferAccountId = null;
    }
  });
}
```

## Clasificación de Cuentas

### Activos (isAsset = true)
Suman al patrimonio neto:
- `cash` - Efectivo
- `bank` - Cuenta bancaria
- `wallet` - Billetera digital
- `savings` - Ahorros
- `investment` - Inversiones
- `receivable` - Me deben (dinero prestado a otros)

### Pasivos (isLiability = true)
Restan al patrimonio neto:
- `credit` - Tarjeta de crédito
- `loan` - Préstamo
- `payable` - Debo pagar

## Tests

Ubicación: `test/unit/default_account_selector_test.dart`

14 tests unitarios cubren:
- Selección correcta para cada tipo de transacción
- Priorización de cuentas de activo
- Fallback a pasivos cuando no hay activos
- Exclusión de cuenta origen en transferencias
- Casos edge (lista vacía, una sola cuenta)

## Archivos Relacionados

| Archivo | Responsabilidad |
|---------|-----------------|
| `lib/.../helpers/default_account_selector.dart` | Lógica de selección |
| `lib/.../widgets/add_transaction_sheet.dart` | UI del formulario |
| `lib/.../domain/models/account_model.dart` | Tipos de cuenta |
| `test/unit/default_account_selector_test.dart` | Tests unitarios |
