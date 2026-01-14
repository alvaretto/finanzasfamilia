import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../application/providers/categories_provider.dart';
import '../../application/providers/database_provider.dart';

/// Widget selector de categorías jerárquico
/// Muestra categorías en estructura de árbol expandible
class HierarchicalCategorySelector extends ConsumerStatefulWidget {
  const HierarchicalCategorySelector({
    super.key,
    required this.categoryType,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.showOnlyLeaves = false,
    this.label = 'Categoría',
  });

  /// Tipo de categoría a mostrar (expense, income, asset, liability)
  final String categoryType;

  /// ID de categoría seleccionada inicialmente
  final String? selectedCategoryId;

  /// Callback cuando se selecciona una categoría
  final ValueChanged<CategoryEntry> onCategorySelected;

  /// Si true, solo permite seleccionar categorías hoja (sin hijos)
  final bool showOnlyLeaves;

  /// Etiqueta del campo
  final String label;

  @override
  ConsumerState<HierarchicalCategorySelector> createState() =>
      _HierarchicalCategorySelectorState();
}

class _HierarchicalCategorySelectorState
    extends ConsumerState<HierarchicalCategorySelector> {
  CategoryEntry? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadSelectedCategory();
  }

  Future<void> _loadSelectedCategory() async {
    if (widget.selectedCategoryId != null) {
      final dao = ref.read(categoriesDaoProvider);
      final category = await dao.getCategoryById(widget.selectedCategoryId!);
      if (mounted && category != null) {
        setState(() => _selectedCategory = category);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCategoryPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.category),
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: _selectedCategory != null
            ? Row(
                children: [
                  Text(
                    _selectedCategory!.icon ?? '📁',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildCategoryPath(_selectedCategory!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Text(
                'Seleccionar categoría',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                ),
              ),
      ),
    );
  }

  String _buildCategoryPath(CategoryEntry category) {
    // Mostrar solo el nombre, el path completo se muestra en el picker
    return category.name;
  }

  Future<void> _showCategoryPicker(BuildContext context) async {
    final result = await showModalBottomSheet<CategoryEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CategoryPickerSheet(
        categoryType: widget.categoryType,
        selectedCategoryId: _selectedCategory?.id,
        showOnlyLeaves: widget.showOnlyLeaves,
      ),
    );

    if (result != null) {
      setState(() => _selectedCategory = result);
      widget.onCategorySelected(result);
    }
  }
}

/// Sheet con el árbol de categorías
class _CategoryPickerSheet extends ConsumerStatefulWidget {
  const _CategoryPickerSheet({
    required this.categoryType,
    this.selectedCategoryId,
    this.showOnlyLeaves = false,
  });

  final String categoryType;
  final String? selectedCategoryId;
  final bool showOnlyLeaves;

  @override
  ConsumerState<_CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  final Set<String> _expandedIds = {};
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync =
        ref.watch(categoriesByTypeProvider(widget.categoryType));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) => _buildCategoryTree(
                  categories,
                  scrollController,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_tree),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Seleccionar Categoría',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar categoría...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          isDense: true,
          suffixIcon: _searchQuery?.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = null);
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.isEmpty ? null : value);
        },
      ),
    );
  }

  Widget _buildCategoryTree(
    List<CategoryEntry> categories,
    ScrollController scrollController,
  ) {
    // Filtrar por búsqueda si hay query
    List<CategoryEntry> filteredCategories = categories;
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filteredCategories = categories
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();

      // Si hay búsqueda, mostrar lista plana
      return ListView.builder(
        controller: scrollController,
        itemCount: filteredCategories.length,
        itemBuilder: (context, index) {
          final category = filteredCategories[index];
          return _buildSearchResultTile(category, categories);
        },
      );
    }

    // Sin búsqueda: mostrar árbol jerárquico
    final rootCategories = categories.where((c) => c.parentId == null).toList()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));

    return ListView.builder(
      controller: scrollController,
      itemCount: rootCategories.length,
      itemBuilder: (context, index) {
        final category = rootCategories[index];
        return _buildCategoryNode(category, categories, 0);
      },
    );
  }

  Widget _buildSearchResultTile(
    CategoryEntry category,
    List<CategoryEntry> allCategories,
  ) {
    final path = _buildFullPath(category, allCategories);
    final hasChildren = allCategories.any((c) => c.parentId == category.id);
    final canSelect = !widget.showOnlyLeaves || !hasChildren;

    return ListTile(
      leading: Text(
        category.icon ?? '📁',
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(category.name),
      subtitle: Text(
        path,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).hintColor,
        ),
      ),
      selected: category.id == widget.selectedCategoryId,
      enabled: canSelect,
      onTap: canSelect ? () => Navigator.pop(context, category) : null,
    );
  }

  String _buildFullPath(CategoryEntry category, List<CategoryEntry> all) {
    final parts = <String>[];
    CategoryEntry? current = category;

    while (current != null) {
      parts.insert(0, current.name);
      if (current.parentId != null) {
        current = all.where((c) => c.id == current!.parentId).firstOrNull;
      } else {
        current = null;
      }
    }

    return parts.join(' > ');
  }

  Widget _buildCategoryNode(
    CategoryEntry category,
    List<CategoryEntry> allCategories,
    int depth,
  ) {
    final children = allCategories
        .where((c) => c.parentId == category.id)
        .toList()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));

    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedIds.contains(category.id);
    final isSelected = category.id == widget.selectedCategoryId;
    final canSelect = !widget.showOnlyLeaves || !hasChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (hasChildren) {
              setState(() {
                if (isExpanded) {
                  _expandedIds.remove(category.id);
                } else {
                  _expandedIds.add(category.id);
                }
              });
            }
            if (canSelect) {
              Navigator.pop(context, category);
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + (depth * 24.0),
              right: 16,
              top: 12,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
            child: Row(
              children: [
                // Icono de expansión o espacio
                SizedBox(
                  width: 24,
                  child: hasChildren
                      ? Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 20,
                        )
                      : null,
                ),
                // Icono de categoría
                Text(
                  category.icon ?? '📁',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                // Nombre
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight:
                          hasChildren ? FontWeight.w600 : FontWeight.normal,
                      color: canSelect
                          ? null
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                ),
                // Indicador de seleccionado
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        // Hijos si está expandido
        if (hasChildren && isExpanded)
          ...children.map(
            (child) => _buildCategoryNode(child, allCategories, depth + 1),
          ),
      ],
    );
  }
}

/// Versión simplificada del selector para formularios rápidos
class SimpleCategoryDropdown extends ConsumerWidget {
  const SimpleCategoryDropdown({
    super.key,
    required this.categoryType,
    this.selectedCategoryId,
    required this.onChanged,
    this.label = 'Categoría',
    this.validator,
  });

  final String categoryType;
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;
  final String label;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(categoryType));

    return categoriesAsync.when(
      data: (categories) {
        // Solo mostrar categorías hoja (sin hijos) para selección rápida
        final leafCategories = categories.where((c) {
          return !categories.any((other) => other.parentId == c.id);
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return DropdownButtonFormField<String>(
          initialValue: selectedCategoryId,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.category),
            border: const OutlineInputBorder(),
          ),
          items: leafCategories.map((category) {
            return DropdownMenuItem(
              value: category.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.icon ?? '📁',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error cargando categorías'),
    );
  }
}
