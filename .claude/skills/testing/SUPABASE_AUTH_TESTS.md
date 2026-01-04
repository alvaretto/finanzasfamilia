# Supabase Authentication Testing

## Scope
Tests de autenticacion, sesiones y seguridad de usuarios.

## Test Categories

### 1. Repository Tests
- AuthRepository se instancia correctamente
- currentUser es null sin sesion
- isAuthenticated retorna false sin login
- signOut completa sin error
- authStateChanges emite stream

### 2. Validation Tests
- Emails validos pasan validacion
- Emails invalidos fallan
- Passwords fuertes pasan
- Passwords debiles fallan

### 3. Session Management
- Test mode no tiene sesion activa
- Operaciones no crashean en test mode

### 4. Error Handling
- Credenciales vacias retornan error
- Datos invalidos retornan error

## Validaciones

### Email
```dart
bool _isValidEmail(String email) {
  if (email.isEmpty) return false;
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}
```

### Password
```dart
bool _isStrongPassword(String password) {
  if (password.length < 8) return false;
  final hasUppercase = password.contains(RegExp(r'[A-Z]'));
  final hasLowercase = password.contains(RegExp(r'[a-z]'));
  final hasDigit = password.contains(RegExp(r'[0-9]'));
  final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  return hasUppercase && hasLowercase && hasDigit && hasSpecial;
}
```

## Security Considerations

1. **Never log credentials** - No imprimir passwords en tests
2. **Use test mode** - No conectar a Supabase real en tests
3. **Validate errors** - Verificar que errores son descriptivos pero no revelan info sensible
