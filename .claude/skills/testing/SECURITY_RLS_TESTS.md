# Security & RLS Testing

## Objetivo
Verificar que Row Level Security (RLS) funciona y usuarios solo acceden a sus datos.

## Tests de Aislamiento

### 1. User Data Isolation
- Cuentas se filtran por userId
- Transacciones se filtran por userId
- Presupuestos se filtran por userId
- Metas se filtran por userId

### 2. Data Validation
- userId vacio es rechazado/manejado
- Montos negativos permitidos (deudas)
- Montos cero permitidos

### 3. Sync Security
- syncWithSupabase requiere userId explicito
- getUnsyncedAccounts retorna datos del usuario

### 4. Input Sanitization
- Caracteres especiales en nombres
- SQL injection attempts
- XSS attempts en descripciones

## Patron de Test

```dart
test('Datos filtrados por userId', () async {
  final repo = Repository();

  // Crear para user1
  await repo.create(item.copyWith(userId: 'user1'));

  // Crear para user2
  await repo.create(item.copyWith(userId: 'user2'));

  // Query user1
  final user1Data = await repo.watch('user1').first;

  // Verificar aislamiento
  expect(user1Data.every((d) => d.userId == 'user1'), true);
  expect(user1Data.any((d) => d.userId == 'user2'), false);
});
```

## Casos de Inyeccion

```dart
final dangerousInputs = [
  "'; DROP TABLE accounts; --",
  "<script>alert('XSS')</script>",
  '\${system.exit()}',
  "1=1",
];
```

Todos deben ser almacenados como texto plano, no ejecutados.
