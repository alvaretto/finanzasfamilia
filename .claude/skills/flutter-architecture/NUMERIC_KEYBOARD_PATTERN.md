# Patron: Teclado Numerico en Flutter Android

## Problema

En Android, `TextInputType.numberWithOptions(decimal: true)` puede no mostrar el teclado numerico correctamente, especialmente dentro de `ModalBottomSheet`.

## Solucion: Patron Robusto

### 1. Declarar FocusNodes

```dart
class _MyFormState extends State<MyForm> {
  final _nameFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }
}
```

### 2. Campo de Texto (String)

```dart
TextFormField(
  controller: _nameController,
  focusNode: _nameFocusNode,
  textInputAction: TextInputAction.next,
  onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
  // ...
),
```

### 3. Campo Numerico (Dinero)

```dart
TextFormField(
  controller: _amountController,
  focusNode: _amountFocusNode,
  // CRITICO: Especificar signed: false
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
    signed: false,  // <-- Importante para Android
  ),
  textInputAction: TextInputAction.done,
  inputFormatters: [
    // Permitir vacio, numeros, un punto, hasta 2 decimales
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ],
  decoration: const InputDecoration(
    hintText: '0.00',
    prefixIcon: Icon(Icons.attach_money),
  ),
),
```

## Puntos Clave

| Aspecto | Incorrecto | Correcto |
|---------|------------|----------|
| FocusNode | Sin FocusNode | FocusNode explicito + dispose() |
| keyboardType | `numberWithOptions(decimal: true)` | `numberWithOptions(decimal: true, signed: false)` |
| textInputAction | Sin especificar | `TextInputAction.next` o `done` |
| RegExp | `r'^\d+\.?\d{0,2}'` (requiere digito) | `r'^\d*\.?\d{0,2}'` (permite vacio) |
| Navegacion | Sin navegacion | `onFieldSubmitted` + `requestFocus()` |

## Aplicacion en Finanzas Familiares

Este patron se aplica en:

- `lib/features/accounts/presentation/widgets/add_account_sheet.dart`
- `lib/features/accounts/presentation/widgets/first_account_wizard.dart`
- `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`
- Cualquier formulario con campos monetarios

## Error Relacionado

Ver [ERR-0004](../../../.error-tracker/errors/ERR-0004.json) para documentacion completa del bug y su resolucion.

## Test de Regresion

```dart
// test/regression/numeric_keyboard_test.dart
testWidgets('Balance field uses numeric keyboard', (tester) async {
  await tester.pumpWidget(/* ... */);

  final balanceField = find.byType(TextFormField).at(1);
  final textField = tester.widget<TextFormField>(balanceField);

  expect(
    textField.keyboardType,
    equals(const TextInputType.numberWithOptions(
      decimal: true,
      signed: false,
    )),
  );
});
```
