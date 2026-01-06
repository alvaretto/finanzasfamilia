import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/establishment_model.dart';
import 'package:finanzas_familiares/core/models/payment_enums.dart';

void main() {
  group('EstablishmentModel', () {
    test('create genera ID único', () {
      final est1 = EstablishmentModel.create(
        userId: 'user1',
        name: 'Supermercado Test',
      );
      final est2 = EstablishmentModel.create(
        userId: 'user1',
        name: 'Supermercado Test',
      );

      expect(est1.id, isNotEmpty);
      expect(est2.id, isNotEmpty);
      expect(est1.id, isNot(equals(est2.id)));
    });

    test('create establece valores por defecto', () {
      final est = EstablishmentModel.create(
        userId: 'user1',
        name: 'Tienda',
      );

      expect(est.useCount, 1);
      expect(est.isSynced, false);
      expect(est.createdAt, isNotNull);
      expect(est.updatedAt, isNotNull);
    });

    test('categoryEnum retorna categoría tipada', () {
      final est = EstablishmentModel(
        id: 'test',
        userId: 'user1',
        name: 'Test',
        category: 'supermercado',
      );

      expect(est.categoryEnum, EstablishmentCategory.supermercado);
    });

    test('categoryEnum retorna null para categoría inválida', () {
      final est = EstablishmentModel(
        id: 'test',
        userId: 'user1',
        name: 'Test',
        category: null,
      );

      expect(est.categoryEnum, isNull);
    });

    test('displayNameWithAddress formatea con dirección', () {
      final est = EstablishmentModel(
        id: 'test',
        userId: 'user1',
        name: 'Éxito',
        address: 'Calle 50',
      );

      expect(est.displayNameWithAddress, 'Éxito - Calle 50');
    });

    test('displayNameWithAddress retorna solo nombre sin dirección', () {
      final est = EstablishmentModel(
        id: 'test',
        userId: 'user1',
        name: 'Éxito',
      );

      expect(est.displayNameWithAddress, 'Éxito');
    });

    test('displayIcon usa icono personalizado si existe', () {
      final est = EstablishmentModel(
        id: 'test',
        userId: 'user1',
        name: 'Test',
        icon: 'custom_icon',
      );

      expect(est.displayIcon, 'custom_icon');
    });

    test('displayIcon usa icono de categoría si no hay personalizado', () {
      final est = EstablishmentModel(
        id: 'test',
        userId: 'user1',
        name: 'Test',
        category: 'supermercado',
      );

      expect(est.displayIcon, 'shopping_cart');
    });

    test('displayIcon retorna place como fallback', () {
      final est = EstablishmentModel(
        id: 'test',
        userId: 'user1',
        name: 'Test',
      );

      expect(est.displayIcon, 'place');
    });

    group('toSupabaseMap', () {
      test('genera mapa correcto para Supabase', () {
        final est = EstablishmentModel(
          id: 'est123',
          userId: 'user456',
          name: 'Mi Tienda',
          address: 'Calle 1',
          phone: '123456',
          category: 'tienda',
          useCount: 5,
        );

        final map = est.toSupabaseMap();

        expect(map['id'], 'est123');
        expect(map['user_id'], 'user456');
        expect(map['name'], 'Mi Tienda');
        expect(map['address'], 'Calle 1');
        expect(map['use_count'], 5);
      });
    });

    group('fromSupabase', () {
      test('crea modelo desde respuesta de Supabase', () {
        final json = {
          'id': 'est123',
          'user_id': 'user456',
          'name': 'Supermercado',
          'address': 'Av Principal',
          'phone': null,
          'category': 'supermercado',
          'icon': null,
          'use_count': 10,
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-02T00:00:00.000Z',
        };

        final est = EstablishmentModel.fromSupabase(json);

        expect(est.id, 'est123');
        expect(est.userId, 'user456');
        expect(est.name, 'Supermercado');
        expect(est.useCount, 10);
        expect(est.isSynced, true);
      });

      test('maneja use_count null', () {
        final json = {
          'id': 'est123',
          'user_id': 'user456',
          'name': 'Test',
          'use_count': null,
        };

        final est = EstablishmentModel.fromSupabase(json);
        expect(est.useCount, 0);
      });
    });

    group('toDriftMap', () {
      test('genera mapa para Drift con snake_case', () {
        final est = EstablishmentModel(
          id: 'est123',
          userId: 'user456',
          name: 'Tienda',
          useCount: 3,
          isSynced: false,
        );

        final map = est.toDriftMap();

        expect(map['id'], 'est123');
        expect(map['user_id'], 'user456');
        expect(map['use_count'], 3);
        expect(map['is_synced'], false);
      });
    });

    group('copyWith', () {
      test('crea copia con valores modificados', () {
        final original = EstablishmentModel(
          id: 'est1',
          userId: 'user1',
          name: 'Original',
          useCount: 1,
        );

        final copy = original.copyWith(
          name: 'Modificado',
          useCount: 5,
        );

        expect(copy.id, 'est1');
        expect(copy.name, 'Modificado');
        expect(copy.useCount, 5);
        expect(original.name, 'Original');
        expect(original.useCount, 1);
      });
    });
  });
}
