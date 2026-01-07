# Fix: Formulario de Transacciones - Interacción Táctil y DatePicker

## Problema

En `AddTransactionSheet` (Movimientos > Agregar Transacción), se reportaron múltiples problemas de interacción:

1. **Teclado numérico no aparece** al tocar el campo de monto
2. **Selector de categoría no funciona** (DropdownButtonFormField no responde)
3. **Selector de fecha no funciona** (DatePicker no abre)
4. **"Efectivo" aparece como cuenta predeterminada** en todos los tipos de transacción

## Diagnóstico

### Causa Raíz 1: Falta de Localización
- **Archivo**: `lib/main.dart`
- **Problema**: MaterialApp sin `localizationsDelegates` ni `supportedLocales`
- **Síntoma**: DatePicker no funcionaba correctamente en español

### Causa Raíz 2: Doble Wrapping del BottomSheet
- **Archivo**: `lib/shared/widgets/main_scaffold.dart`
- **Problema**: `showModalBottomSheet` con doble Container wrapping
- **Síntoma**: Gestos táctiles bloqueados en campos del formulario

```dart
// ❌ ANTES (Doble wrapping bloqueaba gestos)
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => Container(
    decoration: BoxDecoration(...),
    child: AddTransactionSheet(initialType: type),
  ),
);
```

### Causa Raíz 3: Campo de Monto con Área de Toque Insuficiente
- **Archivo**: `lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`
- **Problema**: IntrinsicWidth limita el área táctil, sin FocusNode dedicado
- **Síntoma**: Difícil activar el teclado numérico al tocar

### Causa Raíz 4: Cuenta Predeterminada (No es un bug)
- **Observación**: DefaultAccountSelector funciona correctamente
- **Explicación**: Si el usuario solo tiene "Efectivo" en sus cuentas, esa será la predeterminada
- **Verificación**: Prioridad es `bank → wallet → cash → savings → ...`

## Solución Implementada

### 1. Agregar Localización Completa

**pubspec.yaml:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:  # ✅ NUEVO
    sdk: flutter
```

**lib/main.dart:**
```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp.router(
  // ... otras configuraciones
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('es', 'CO'), // Español Colombia (default)
    Locale('es', 'MX'), // Español México
    Locale('es'),       // Español genérico
    Locale('en', 'US'), // English US
    Locale('pt', 'BR'), // Portugués Brasil
  ],
  locale: const Locale('es', 'CO'),
  // ...
)
```

### 2. Eliminar Doble Wrapping en BottomSheet

**lib/shared/widgets/main_scaffold.dart:**
```dart
void _openTransactionForm(BuildContext context, TransactionType type) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,  // ✅ NUEVO
    backgroundColor: Theme.of(context).colorScheme.surface,  // ✅ Directo
    shape: const RoundedRectangleBorder(  // ✅ Shape en showModal
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
    ),
    builder: (context) => AddTransactionSheet(initialType: type),  // ✅ Sin wrapper
  );
}
```

### 3. Mejorar Área Táctil del Campo de Monto

**lib/features/transactions/presentation/widgets/add_transaction_sheet.dart:**

**Agregar FocusNode:**
```dart
class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountFocusNode = FocusNode();  // ✅ NUEVO

  @override
  void dispose() {
    _amountFocusNode.dispose();  // ✅ Limpiar
    super.dispose();
  }
}
```

**Mejora del campo:**
```dart
Widget _buildAmountField() {
  return GestureDetector(
    onTap: () {
      _amountFocusNode.requestFocus();  // ✅ Forzar foco
    },
    behavior: HitTestBehavior.translucent,  // ✅ Capturar toques
    child: Container(
      width: double.infinity,  // ✅ Área de toque completa
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          TextFormField(
            controller: _amountController,
            focusNode: _amountFocusNode,  // ✅ FocusNode dedicado
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // ... resto de configuración
          ),
          Text(
            'Ingresa el monto',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getTypeColor().withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    ),
  );
}
```

## Archivos Modificados

```
.
├── pubspec.yaml                                          (+1 dependency)
├── lib/
│   ├── main.dart                                        (+8 lines localization)
│   ├── shared/widgets/main_scaffold.dart                (-8 lines wrapping)
│   └── features/transactions/presentation/widgets/
│       └── add_transaction_sheet.dart                   (+20 lines FocusNode)
└── .claude/skills/flutter-architecture/
    └── FORM_INTERACTION_FIX.md                          (ESTE ARCHIVO)
```

## Lecciones Aprendidas

### ❌ Anti-Patrones Identificados

1. **Doble Wrapping en BottomSheet**
   ```dart
   // ❌ EVITAR
   showModalBottomSheet(
     builder: (context) => Container(
       decoration: BoxDecoration(...),
       child: Widget(),
     ),
   );
   ```

2. **IntrinsicWidth sin GestureDetector**
   ```dart
   // ❌ EVITAR - Área táctil muy pequeña
   IntrinsicWidth(
     child: TextFormField(...),
   )
   ```

3. **MaterialApp sin localizationsDelegates**
   ```dart
   // ❌ EVITAR - DatePicker no funciona correctamente
   MaterialApp(
     // Falta localizationsDelegates
   )
   ```

### ✅ Buenas Prácticas

1. **BottomSheet con configuración directa**
   ```dart
   showModalBottomSheet(
     backgroundColor: Theme.of(context).colorScheme.surface,
     shape: RoundedRectangleBorder(...),
     builder: (context) => Widget(),  // Sin wrapper
   );
   ```

2. **FocusNode dedicado para campos críticos**
   ```dart
   final _focusNode = FocusNode();

   GestureDetector(
     onTap: () => _focusNode.requestFocus(),
     child: TextFormField(focusNode: _focusNode),
   )
   ```

3. **Localización completa**
   ```dart
   MaterialApp(
     localizationsDelegates: GlobalMaterialLocalizations.delegate,
     supportedLocales: [Locale('es', 'CO')],
   )
   ```

## Testing

### Test Manual
1. Abrir Movimientos → Agregar Transacción
2. Tocar campo de monto → debe aparecer teclado numérico ✅
3. Tocar selector de categoría → debe abrir dropdown ✅
4. Tocar selector de fecha → debe abrir DatePicker en español ✅

### Test de Regresión
```dart
testWidgets('Campo de monto responde al toque', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: AddTransactionSheet(initialType: TransactionType.expense),
      ),
    ),
  );

  final amountField = find.byType(TextFormField).first;
  await tester.tap(amountField);
  await tester.pump();

  // Verificar que el campo tiene foco
  final textField = tester.widget<TextFormField>(amountField);
  expect(textField.focusNode?.hasFocus, isTrue);
});
```

## Versión
- **Fix aplicado en**: v1.9.11
- **APK**: `finanzas-familiares-v1.9.11-fix-form-interaction.apk`
- **Fecha**: 2026-01-06
