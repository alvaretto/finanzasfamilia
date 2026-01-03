import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Tests de inicialización - estos son críticos para detectar
/// por qué la app se congela en el arranque
void main() {
  group('Inicialización de dotenv', () {
    test('dotenv debe cargar sin errores cuando .env existe', () async {
      // Este test verifica que el archivo .env sea válido
      try {
        await dotenv.load(fileName: '.env');
        expect(dotenv.isInitialized, isTrue);
      } catch (e) {
        fail('dotenv.load() falló: $e\n'
            'Esto causará que la app no inicie correctamente');
      }
    });

    test('SUPABASE_URL debe estar definido y ser válido', () async {
      await dotenv.load(fileName: '.env');

      final url = dotenv.env['SUPABASE_URL'];

      expect(url, isNotNull,
          reason: 'SUPABASE_URL no está definido en .env');
      expect(url, isNotEmpty,
          reason: 'SUPABASE_URL está vacío en .env');
      expect(url!.startsWith('https://'),
          isTrue,
          reason: 'SUPABASE_URL debe comenzar con https://');
    });

    test('SUPABASE_ANON_KEY debe estar definido y ser válido', () async {
      await dotenv.load(fileName: '.env');

      final key = dotenv.env['SUPABASE_ANON_KEY'];

      expect(key, isNotNull,
          reason: 'SUPABASE_ANON_KEY no está definido en .env');
      expect(key, isNotEmpty,
          reason: 'SUPABASE_ANON_KEY está vacío en .env');
      expect(key!.length > 100, isTrue,
          reason: 'SUPABASE_ANON_KEY parece demasiado corto para ser un JWT válido');
    });

    test('dotenv con valores vacíos no debe causar crash', () async {
      await dotenv.load(fileName: '.env');

      // Acceder a una variable que no existe
      final nonExistent = dotenv.env['NON_EXISTENT_VAR'];

      expect(nonExistent, isNull,
          reason: 'Acceder a variables no existentes debe retornar null, no crashear');

      // Usar el operador ?? correctamente
      final withDefault = dotenv.env['NON_EXISTENT_VAR'] ?? 'default';
      expect(withDefault, 'default');
    });
  });

  group('Validación de configuración', () {
    test('Variables de entorno críticas deben existir', () async {
      await dotenv.load(fileName: '.env');

      final requiredVars = [
        'SUPABASE_URL',
        'SUPABASE_ANON_KEY',
      ];

      for (final varName in requiredVars) {
        final value = dotenv.env[varName];
        expect(value, isNotNull,
            reason: '$varName es requerido pero no está definido');
        expect(value, isNotEmpty,
            reason: '$varName está vacío');
      }
    });

    test('URL de Supabase debe ser accesible (formato)', () async {
      await dotenv.load(fileName: '.env');

      final url = dotenv.env['SUPABASE_URL']!;

      // Debe ser una URL válida de Supabase
      final uri = Uri.tryParse(url);
      expect(uri, isNotNull, reason: 'SUPABASE_URL no es una URL válida');
      expect(uri!.host.contains('supabase'), isTrue,
          reason: 'SUPABASE_URL debe ser un host de supabase');
    });
  });
}
