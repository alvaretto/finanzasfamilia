import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/category_hierarchy.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final expenseCategories = categories.where((c) => c.type == 'expense').toList();
    final incomeCategories = categories.where((c) => c.type == 'income').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.arrow_downward),
              text: 'Gastos (${expenseCategories.length})',
            ),
            Tab(
              icon: const Icon(Icons.arrow_upward),
              text: 'Ingresos (${incomeCategories.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(
            categories: expenseCategories,
            type: 'expense',
            emptyMessage: 'Sin categorías de gasto',
          ),
          _CategoryList(
            categories: incomeCategories,
            type: 'income',
            emptyMessage: 'Sin categorías de ingreso',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategory(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategory(BuildContext context) {
    final type = _tabController.index == 0 ? 'expense' : 'income';
    final categories = ref.watch(categoriesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFormSheet(
        type: type,
        allCategories: categories,
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final List<CategoryModel> categories;
  final String type;
  final String emptyMessage;

  const _CategoryList({
    required this.categories,
    required this.type,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(emptyMessage),
          ],
        ),
      );
    }

    // Construir árbol jerárquico
    final tree = CategoryHierarchyUtils.buildTree(categories, type);
    final flatItems = CategoryHierarchyUtils.flattenTree(tree);

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: flatItems.length,
      itemBuilder: (context, index) {
        final item = flatItems[index];
        return _CategoryHierarchyTile(
          item: item,
          allCategories: categories,
        );
      },
    );
  }
}

class _CategoryHierarchyTile extends ConsumerWidget {
  final FlatCategoryItem item;
  final List<CategoryModel> allCategories;

  const _CategoryHierarchyTile({
    required this.item,
    required this.allCategories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = item.category;
    final color = _parseColor(category.color) ?? AppColors.primary;
    final level = item.level;

    return Padding(
      padding: EdgeInsets.only(left: item.indentation, bottom: AppSpacing.xs),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: level == 0 ? 1 : 0,
        color: level == 0
            ? null
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: ListTile(
          dense: level > 0,
          leading: CircleAvatar(
            radius: level == 0 ? 20 : 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(
              _getIcon(category.icon),
              color: color,
              size: level == 0 ? 20 : 16,
            ),
          ),
          title: Row(
            children: [
              if (level > 0) ...[
                Text(
                  level == 1 ? '└─' : '  └─',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  category.name,
                  style: level == 0
                      ? Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          )
                      : null,
                ),
              ),
            ],
          ),
          subtitle: _buildSubtitle(context),
          trailing: category.isSystem
              ? const Icon(Icons.lock, size: 16, color: Colors.grey)
              : PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(context, ref, value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (item.hasChildren)
                      const PopupMenuItem(
                        value: 'add_sub',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('Agregar Subcategoría'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppColors.error),
                          SizedBox(width: AppSpacing.sm),
                          Text('Eliminar', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final category = item.category;
    final parts = <String>[];

    if (category.isSystem) {
      parts.add('Sistema');
    }

    if (item.hasChildren) {
      final childCount = CategoryHierarchyUtils.getSubcategories(
        allCategories,
        category.id,
      ).length;
      parts.add('$childCount subcategoría${childCount != 1 ? 's' : ''}');
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' • '),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    final category = item.category;

    if (action == 'edit') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _CategoryFormSheet(
          type: category.type,
          category: category,
          allCategories: allCategories,
        ),
      );
    } else if (action == 'add_sub') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _CategoryFormSheet(
          type: category.type,
          parentId: category.id,
          allCategories: allCategories,
        ),
      );
    } else if (action == 'delete') {
      _confirmDelete(context, ref);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final category = item.category;

    // Check if has children
    if (item.hasChildren) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar: tiene subcategorías'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check usage
    final repository = ref.read(transactionRepositoryProvider);
    final usageCount = await repository.getCategoryUsageCount(category.id);

    if (!context.mounted) return;

    if (usageCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede eliminar: $usageCount transacciones usan esta categoría'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await repository.deleteCategory(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Categoría eliminada' : 'Error al eliminar'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getIcon(String? iconName) {
    const icons = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'shopping_cart': Icons.shopping_cart,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'flight': Icons.flight,
      'movie': Icons.movie,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'work': Icons.work,
      'attach_money': Icons.attach_money,
      'account_balance': Icons.account_balance,
      'card_giftcard': Icons.card_giftcard,
      'savings': Icons.savings,
    };
    return icons[iconName] ?? Icons.category;
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _CategoryTile extends ConsumerWidget {
  final CategoryModel category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(category.color) ?? AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            _getIcon(category.icon),
            color: color,
            size: 20,
          ),
        ),
        title: Text(category.name),
        subtitle: category.isSystem
            ? Text(
                'Categoría del sistema',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : null,
        trailing: category.isSystem
            ? const Icon(Icons.lock, size: 16, color: Colors.grey)
            : PopupMenuButton<String>(
                onSelected: (value) => _handleAction(context, ref, value),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text('Eliminar', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'edit') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _CategoryFormSheet(
          type: category.type,
          category: category,
        ),
      );
    } else if (action == 'delete') {
      _confirmDelete(context, ref);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    // Check usage first
    final repository = ref.read(transactionRepositoryProvider);
    final usageCount = await repository.getCategoryUsageCount(category.id);

    if (!context.mounted) return;

    if (usageCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede eliminar: $usageCount transacciones usan esta categoría'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await repository.deleteCategory(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Categoría eliminada' : 'Error al eliminar'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getIcon(String? iconName) {
    const icons = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'shopping_cart': Icons.shopping_cart,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'flight': Icons.flight,
      'movie': Icons.movie,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'work': Icons.work,
      'attach_money': Icons.attach_money,
      'account_balance': Icons.account_balance,
      'card_giftcard': Icons.card_giftcard,
      'savings': Icons.savings,
    };
    return icons[iconName] ?? Icons.category;
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final String type;
  final CategoryModel? category;
  final String? parentId;
  final List<CategoryModel> allCategories;

  const _CategoryFormSheet({
    required this.type,
    this.category,
    this.parentId,
    this.allCategories = const [],
  });

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'category';
  Color _selectedColor = AppColors.primary;
  String? _selectedParentId;
  bool _isLoading = false;

  bool get isEditing => widget.category != null;

  static const _availableIcons = [
    'category',
    'restaurant',
    'directions_car',
    'home',
    'shopping_cart',
    'local_hospital',
    'school',
    'flight',
    'movie',
    'fitness_center',
    'pets',
    'work',
    'attach_money',
    'account_balance',
    'card_giftcard',
    'savings',
  ];

  static const _availableColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF3F51B5),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.icon ?? 'category';
      _selectedParentId = widget.category!.parentId;
      if (widget.category!.color != null) {
        try {
          _selectedColor = Color(
            int.parse(widget.category!.color!.replaceFirst('#', 'FF'), radix: 16),
          );
        } catch (_) {}
      }
    } else if (widget.parentId != null) {
      _selectedParentId = widget.parentId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = ref.read(transactionRepositoryProvider);
    final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

    try {
      if (isEditing) {
        await repository.updateCategory(
          id: widget.category!.id,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          color: colorHex,
          parentId: _selectedParentId,
        );
      } else {
        final userId = ref.read(authProvider).user!.id;
        await repository.createCategory(
          userId: userId,
          name: _nameController.text.trim(),
          type: widget.type,
          icon: _selectedIcon,
          color: colorHex,
          parentId: _selectedParentId,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Categoría actualizada' : 'Categoría creada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                isEditing ? 'Editar Categoría' : 'Nueva Categoría',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.type == 'expense' ? 'Categoría de gasto' : 'Categoría de ingreso',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Entretenimiento',
                  prefixIcon: Icon(Icons.label),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Parent category selector
              _buildParentSelector(context),
              const SizedBox(height: AppSpacing.lg),

              // Icon selector
              Text(
                'Icono',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _availableIcons.map((iconName) {
                  final isSelected = _selectedIcon == iconName;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = iconName),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withValues(alpha: 0.2)
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: isSelected
                            ? Border.all(color: _selectedColor, width: 2)
                            : null,
                      ),
                      child: Icon(
                        _getIconData(iconName),
                        color: isSelected ? _selectedColor : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Color selector
              Text(
                'Color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _availableColors.map((color) {
                  final isSelected = _selectedColor.value == color.value;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit button
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Guardar' : 'Crear'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentSelector(BuildContext context) {
    // Obtener categorías válidas como padre
    final validParents = widget.allCategories
        .where((c) =>
            c.type == widget.type &&
            (widget.category == null || c.id != widget.category!.id) &&
            (widget.category == null ||
                CategoryHierarchyUtils.isValidParent(
                  widget.allCategories,
                  widget.category!,
                  c.id,
                )))
        .toList();

    // Filtrar solo categorías de nivel 0 y 1 (no nivel 2)
    final level0And1 = validParents.where((c) {
      final level = CategoryHierarchyUtils.getCategoryLevel(widget.allCategories, c);
      return level <= 1;
    }).toList();

    if (level0And1.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedParent = _selectedParentId != null
        ? widget.allCategories.firstWhere(
            (c) => c.id == _selectedParentId,
            orElse: () => widget.allCategories.first,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría Padre (Opcional)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String?>(
          value: _selectedParentId,
          decoration: const InputDecoration(
            hintText: 'Ninguna (categoría principal)',
            prefixIcon: Icon(Icons.folder_open),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Ninguna (categoría principal)'),
            ),
            ...level0And1.map((category) {
              final path = CategoryHierarchyUtils.getCategoryPath(
                widget.allCategories,
                category,
              );
              final level = CategoryHierarchyUtils.getCategoryLevel(
                widget.allCategories,
                category,
              );
              return DropdownMenuItem<String?>(
                value: category.id,
                child: Row(
                  children: [
                    if (level > 0)
                      const Padding(
                        padding: EdgeInsets.only(right: AppSpacing.xs),
                        child: Text('  └─ ',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    Expanded(child: Text(path)),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() => _selectedParentId = value);
          },
        ),
        if (_selectedParentId != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nivel: ${CategoryHierarchyUtils.getCategoryLevel(widget.allCategories, selectedParent!) + 2}/3',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ],
    );
  }

  IconData _getIconData(String name) {
    const icons = {
      'category': Icons.category,
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'shopping_cart': Icons.shopping_cart,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'flight': Icons.flight,
      'movie': Icons.movie,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'work': Icons.work,
      'attach_money': Icons.attach_money,
      'account_balance': Icons.account_balance,
      'card_giftcard': Icons.card_giftcard,
      'savings': Icons.savings,
    };
    return icons[name] ?? Icons.category;
  }
}
