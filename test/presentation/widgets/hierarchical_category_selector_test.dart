import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/presentation/widgets/hierarchical_category_selector.dart';
import 'package:finanzas_familiares/application/providers/categories_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';

void main() {
  // Datos de prueba
  final mockCategories = [
    // Raíz
    CategoryEntry(
      id: 'expense-root',
      name: 'Gastos',
      type: 'expense',
      parentId: null,
      level: 0,
      sortOrder: 0,
      icon: '💸',
      isActive: true,
      isSystem: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    // Nivel 1
    CategoryEntry(
      id: 'expense-food',
      name: 'Alimentación',
      type: 'expense',
      parentId: 'expense-root',
      level: 1,
      sortOrder: 0,
      icon: '🍽️',
      isActive: true,
      isSystem: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CategoryEntry(
      id: 'expense-transport',
      name: 'Transporte',
      type: 'expense',
      parentId: 'expense-root',
      level: 1,
      sortOrder: 1,
      icon: '🚗',
      isActive: true,
      isSystem: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    // Nivel 2
    CategoryEntry(
      id: 'expense-food-market',
      name: 'Mercado',
      type: 'expense',
      parentId: 'expense-food',
      level: 2,
      sortOrder: 0,
      icon: '🛒',
      isActive: true,
      isSystem: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CategoryEntry(
      id: 'expense-food-restaurant',
      name: 'Restaurantes',
      type: 'expense',
      parentId: 'expense-food',
      level: 2,
      sortOrder: 1,
      icon: '🍔',
      isActive: true,
      isSystem: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // DTOs para tests de CategoryTreeNode
  final mockCategoryDtos = [
    const CategoryTreeDto(
      id: 'expense-root',
      name: 'Gastos',
      type: 'expense',
      parentId: null,
      level: 0,
      sortOrder: 0,
      icon: '💸',
    ),
    const CategoryTreeDto(
      id: 'expense-food',
      name: 'Alimentación',
      type: 'expense',
      parentId: 'expense-root',
      level: 1,
      sortOrder: 0,
      icon: '🍽️',
    ),
    const CategoryTreeDto(
      id: 'expense-transport',
      name: 'Transporte',
      type: 'expense',
      parentId: 'expense-root',
      level: 1,
      sortOrder: 1,
      icon: '🚗',
    ),
    const CategoryTreeDto(
      id: 'expense-food-market',
      name: 'Mercado',
      type: 'expense',
      parentId: 'expense-food',
      level: 2,
      sortOrder: 0,
      icon: '🛒',
    ),
    const CategoryTreeDto(
      id: 'expense-food-restaurant',
      name: 'Restaurantes',
      type: 'expense',
      parentId: 'expense-food',
      level: 2,
      sortOrder: 1,
      icon: '🍔',
    ),
  ];

  group('HierarchicalCategorySelector', () {
    Widget createTestWidget({
      String? selectedCategoryId,
      bool showOnlyLeaves = false,
    }) {
      return ProviderScope(
        overrides: [
          categoriesByTypeProvider('expense').overrideWith((ref) async {
            return mockCategories;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: HierarchicalCategorySelector(
                categoryType: 'expense',
                selectedCategoryId: selectedCategoryId,
                showOnlyLeaves: showOnlyLeaves,
                onCategorySelected: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('muestra label "Categoría" por defecto', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Categoría'), findsOneWidget);
    });

    testWidgets('muestra "Seleccionar categoría" cuando no hay selección',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Seleccionar categoría'), findsOneWidget);
    });

    testWidgets('muestra icono de categoría', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('muestra icono de dropdown', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('abre bottom sheet al tocar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seleccionar categoría'));
      await tester.pumpAndSettle();

      expect(find.text('Seleccionar Categoría'), findsOneWidget);
    });

    testWidgets('bottom sheet muestra barra de búsqueda', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seleccionar categoría'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar categoría...'), findsOneWidget);
    });

    testWidgets('bottom sheet tiene botón de cerrar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seleccionar categoría'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('SimpleCategoryDropdown', () {
    Widget createSimpleDropdown({String? selectedCategoryId}) {
      return ProviderScope(
        overrides: [
          categoriesByTypeProvider('expense').overrideWith((ref) async {
            return mockCategories;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SimpleCategoryDropdown(
                categoryType: 'expense',
                selectedCategoryId: selectedCategoryId,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('muestra label "Categoría"', (tester) async {
      await tester.pumpWidget(createSimpleDropdown());
      await tester.pumpAndSettle();

      expect(find.text('Categoría'), findsOneWidget);
    });

    testWidgets('muestra icono de categoría', (tester) async {
      await tester.pumpWidget(createSimpleDropdown());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('renderiza dropdown correctamente', (tester) async {
      await tester.pumpWidget(createSimpleDropdown());
      await tester.pumpAndSettle();

      // Verifica que el dropdown existe
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });
  });

  group('CategoryTreeNode', () {
    test('hasChildren es true cuando tiene hijos', () {
      final parent = CategoryTreeNode(
        category: mockCategoryDtos[0],
        children: [
          CategoryTreeNode(category: mockCategoryDtos[1]),
        ],
      );

      expect(parent.hasChildren, isTrue);
    });

    test('hasChildren es false cuando no tiene hijos', () {
      final leaf = CategoryTreeNode(
        category: mockCategoryDtos[3],
        children: [],
      );

      expect(leaf.hasChildren, isFalse);
    });

    test('isLeaf es true cuando no tiene hijos', () {
      final leaf = CategoryTreeNode(
        category: mockCategoryDtos[3],
        children: [],
      );

      expect(leaf.isLeaf, isTrue);
    });

    test('isLeaf es false cuando tiene hijos', () {
      final parent = CategoryTreeNode(
        category: mockCategoryDtos[0],
        children: [
          CategoryTreeNode(category: mockCategoryDtos[1]),
        ],
      );

      expect(parent.isLeaf, isFalse);
    });

    test('getPath construye ruta completa', () {
      final node = CategoryTreeNode(category: mockCategoryDtos[3]); // Mercado

      final path = node.getPath(mockCategoryDtos);

      expect(path, equals('Gastos > Alimentación > Mercado'));
    });
  });
}
