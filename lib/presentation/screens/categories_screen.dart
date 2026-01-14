import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/providers.dart';
import '../../data/local/database.dart';
import 'category_form_screen.dart';

/// Provider para el tipo de categoría seleccionado
final selectedCategoryTypeProvider = StateProvider<String>((ref) => 'expense');

/// Provider para la categoría expandida
final expandedCategoryProvider = StateProvider<String?>((ref) => null);

/// Pantalla de gestión de categorías
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedCategoryTypeProvider);
    final categoriesAsync = ref.watch(categoriesByTypeProvider(selectedType));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(categoriesByTypeProvider(selectedType)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de tipo
          _CategoryTypeSelector(
            selectedType: selectedType,
            onTypeSelected: (type) {
              ref.read(selectedCategoryTypeProvider.notifier).state = type;
            },
          ),

          // Lista de categorías
          Expanded(
            child: categoriesAsync.when(
              data: (categories) => _CategoriesTreeView(
                categories: categories,
                type: selectedType,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(categoriesByTypeProvider(selectedType)),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeSelected;

  const _CategoryTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'expense',
            label: Text('Gastos'),
            icon: Icon(Icons.arrow_upward),
          ),
          ButtonSegment(
            value: 'income',
            label: Text('Ingresos'),
            icon: Icon(Icons.arrow_downward),
          ),
          ButtonSegment(
            value: 'asset',
            label: Text('Activos'),
            icon: Icon(Icons.account_balance),
          ),
        ],
        selected: {selectedType},
        onSelectionChanged: (selection) {
          onTypeSelected(selection.first);
        },
      ),
    );
  }
}

class _CategoriesTreeView extends ConsumerWidget {
  final List<CategoryEntry> categories;
  final String type;

  const _CategoriesTreeView({
    required this.categories,
    required this.type,
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
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay categorías de ${_getTypeLabel(type)}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Obtener solo las categorías raíz (nivel 1)
    final rootCategories = categories.where((c) => c.level == 1).toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: rootCategories.length,
      itemBuilder: (context, index) {
        final root = rootCategories[index];
        return _CategoryTreeNode(
          category: root,
          allCategories: categories,
          level: 0,
        );
      },
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'expense':
        return 'gastos';
      case 'income':
        return 'ingresos';
      case 'asset':
        return 'activos';
      case 'liability':
        return 'pasivos';
      default:
        return type;
    }
  }
}

class _CategoryTreeNode extends ConsumerWidget {
  final CategoryEntry category;
  final List<CategoryEntry> allCategories;
  final int level;

  const _CategoryTreeNode({
    required this.category,
    required this.allCategories,
    required this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedId = ref.watch(expandedCategoryProvider);
    final isExpanded = expandedId == category.id;

    // Encontrar hijos de esta categoría
    final children = allCategories.where((c) => c.parentId == category.id).toList();
    final hasChildren = children.isNotEmpty;

    return Column(
      children: [
        _CategoryTile(
          category: category,
          level: level,
          hasChildren: hasChildren,
          isExpanded: isExpanded,
          onTap: () {
            if (hasChildren) {
              ref.read(expandedCategoryProvider.notifier).state =
                  isExpanded ? null : category.id;
            } else {
              _showCategoryDetail(context, category);
            }
          },
          onLongPress: () => _showCategoryDetail(context, category),
        ),
        if (isExpanded && hasChildren)
          ...children.map((child) => _CategoryTreeNode(
            category: child,
            allCategories: allCategories,
            level: level + 1,
          )),
      ],
    );
  }

  void _showCategoryDetail(BuildContext context, CategoryEntry category) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _CategoryDetailSheet(category: category),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryEntry category;
  final int level;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CategoryTile({
    required this.category,
    required this.level,
    required this.hasChildren,
    required this.isExpanded,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final indent = 16.0 * level;

    return ListTile(
      contentPadding: EdgeInsets.only(left: 16 + indent, right: 16),
      leading: CircleAvatar(
        backgroundColor: _getTypeColor(category.type).withValues(alpha: 0.2),
        child: category.icon != null
            ? Text(category.icon!, style: const TextStyle(fontSize: 20))
            : Icon(
                _getTypeIcon(category.type),
                color: _getTypeColor(category.type),
              ),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontWeight: level == 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: (category.isSystem ?? false)
          ? Text(
              'Sistema',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            )
          : null,
      trailing: hasChildren
          ? Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
            )
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'asset':
        return Colors.blue;
      case 'liability':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward;
      case 'expense':
        return Icons.arrow_upward;
      case 'asset':
        return Icons.account_balance;
      case 'liability':
        return Icons.credit_card;
      default:
        return Icons.category;
    }
  }
}

class _CategoryDetailSheet extends ConsumerWidget {
  final CategoryEntry category;

  const _CategoryDetailSheet({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getTypeColor(category.type).withValues(alpha: 0.2),
                child: category.icon != null
                    ? Text(category.icon!, style: const TextStyle(fontSize: 28))
                    : Icon(
                        _getTypeIcon(category.type),
                        color: _getTypeColor(category.type),
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      _getTypeLabel(category.type),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 32),
          _InfoRow(
            icon: Icons.layers,
            label: 'Nivel',
            value: 'Nivel ${category.level ?? 0}',
          ),
          _InfoRow(
            icon: Icons.check_circle,
            label: 'Estado',
            value: (category.isActive ?? true) ? 'Activa' : 'Inactiva',
          ),
          _InfoRow(
            icon: Icons.lock,
            label: 'Tipo',
            value: (category.isSystem ?? false) ? 'Del sistema (no editable)' : 'Personalizada',
          ),
          const SizedBox(height: 24),
          if (!(category.isSystem ?? false))
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editCategory(context, ref),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteCategory(context, ref),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _editCategory(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(category: category),
      ),
    );
    if (result == true) {
      ref.invalidate(categoriesByTypeProvider(category.type));
    }
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Estás seguro de eliminar "${category.name}"?\n\n'
          'Las transacciones asociadas quedarán sin categoría.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final categoriesDao = ref.read(categoriesDaoProvider);
        await categoriesDao.deleteCategory(category.id);

        if (context.mounted) {
          Navigator.pop(context);
          ref.invalidate(categoriesByTypeProvider(category.type));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoría eliminada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se puede eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Categoría de ingreso';
      case 'expense':
        return 'Categoría de gasto';
      case 'asset':
        return 'Categoría de activo';
      case 'liability':
        return 'Categoría de pasivo';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'asset':
        return Colors.blue;
      case 'liability':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward;
      case 'expense':
        return Icons.arrow_upward;
      case 'asset':
        return Icons.account_balance;
      case 'liability':
        return Icons.credit_card;
      default:
        return Icons.category;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
