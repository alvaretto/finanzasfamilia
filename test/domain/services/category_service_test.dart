import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/domain/exceptions/accounting_exceptions.dart';
import 'package:finanzas_familiares/domain/repositories/category_repository.dart';
import 'package:finanzas_familiares/domain/services/category_service.dart';

class MockCategoryRepository implements CategoryRepository {
  final Map<String, CategoryData> _categories = {};

  void addCategory(String id, String name,
      {String? parentId, bool isSystem = false}) {
    _categories[id] = CategoryData(
      id: id,
      name: name,
      type: 'expense',
      parentId: parentId,
      level: parentId == null ? 0 : 1,
      isSystem: isSystem,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<CategoryData?> getCategoryById(String id) async => _categories[id];

  @override
  Future<List<CategoryData>> getAllCategories() async =>
      _categories.values.toList();

  @override
  Future<List<CategoryData>> getChildCategories(String parentId) async =>
      _categories.values.where((c) => c.parentId == parentId).toList();

  @override
  Future<int> countChildren(String categoryId) async =>
      _categories.values.where((c) => c.parentId == categoryId).length;

  @override
  Future<void> insertCategory(CategoryData category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    _categories.remove(categoryId);
  }
}

void main() {
  group('CategoryService - Validación de eliminación', () {
    late CategoryService service;
    late MockCategoryRepository categoryRepo;

    setUp(() {
      categoryRepo = MockCategoryRepository();
      service = CategoryService(categoryRepository: categoryRepo);
    });

    test('permite eliminar categoría sin hijos', () async {
      categoryRepo.addCategory('cat1', 'Categoría Hoja');

      // No debería lanzar excepción
      await service.validateCategoryDeletion('cat1');
    });

    test('rechaza eliminar categoría con hijos', () async {
      categoryRepo.addCategory('padre', 'Categoría Padre');
      categoryRepo.addCategory('hijo1', 'Hijo 1', parentId: 'padre');
      categoryRepo.addCategory('hijo2', 'Hijo 2', parentId: 'padre');

      expect(
        () => service.validateCategoryDeletion('padre'),
        throwsA(isA<CategoryHasChildrenException>()
            .having((e) => e.categoryName, 'categoryName', 'Categoría Padre')
            .having((e) => e.childCount, 'childCount', 2)),
      );
    });

    test('rechaza eliminar categoría del sistema', () async {
      categoryRepo.addCategory('system-cat', 'Categoría Sistema',
          isSystem: true);

      expect(
        () => service.validateCategoryDeletion('system-cat'),
        throwsA(isA<SystemCategoryException>()
            .having(
                (e) => e.categoryName, 'categoryName', 'Categoría Sistema')),
      );
    });

    test('lanza error si la categoría no existe', () async {
      expect(
        () => service.validateCategoryDeletion('no-existe'),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteCategory elimina después de validar', () async {
      categoryRepo.addCategory('cat1', 'Categoría Eliminable');

      await service.deleteCategory('cat1');

      expect(await categoryRepo.getCategoryById('cat1'), isNull);
    });

    test('deleteCategory no elimina si tiene hijos', () async {
      categoryRepo.addCategory('padre', 'Categoría Padre');
      categoryRepo.addCategory('hijo', 'Hijo', parentId: 'padre');

      expect(
        () => service.deleteCategory('padre'),
        throwsA(isA<CategoryHasChildrenException>()),
      );

      // Verificar que no se eliminó
      expect(await categoryRepo.getCategoryById('padre'), isNotNull);
    });
  });

  group('CategoryHasChildrenException', () {
    test('toString formatea correctamente el mensaje', () {
      const exception = CategoryHasChildrenException(
        categoryName: 'Alimentación',
        childCount: 5,
      );

      expect(exception.toString(), contains('No se puede eliminar'));
      expect(exception.toString(), contains('Alimentación'));
      expect(exception.toString(), contains('5 subcategoría'));
    });
  });

  group('SystemCategoryException', () {
    test('toString formatea correctamente el mensaje', () {
      const exception = SystemCategoryException(
        categoryName: 'Transferencias',
      );

      expect(exception.toString(), contains('No se puede eliminar'));
      expect(exception.toString(), contains('Transferencias'));
      expect(exception.toString(), contains('sistema'));
    });
  });
}
