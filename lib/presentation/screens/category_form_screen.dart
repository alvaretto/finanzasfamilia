import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/providers/database_provider.dart';
import '../../application/providers/categories_provider.dart';
import '../../data/local/database.dart';

/// Lista de iconos disponibles para categorías
const _availableIcons = [
  '🏠', '🍔', '🚗', '💡', '📱', '👕', '🎬', '✈️', '🏥', '📚',
  '💼', '🎁', '💰', '🏦', '💳', '📊', '🛒', '🍷', '☕', '🎮',
  '🏋️', '💊', '🐕', '👶', '🎨', '🔧', '📦', '🎵', '🌐', '⚡',
];

/// Provider para el tipo de categoría seleccionado en el form
final formCategoryTypeProvider = StateProvider<String>((ref) => 'expense');

/// Provider para el icono seleccionado
final selectedIconProvider = StateProvider<String>((ref) => '📁');

/// Provider para la categoría padre seleccionada
final selectedParentIdProvider = StateProvider<String?>((ref) => null);

/// Pantalla de formulario para crear/editar categorías
class CategoryFormScreen extends ConsumerStatefulWidget {
  final CategoryEntry? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _initializeForEdit();
    }
  }

  void _initializeForEdit() {
    final cat = widget.category!;
    _nameController.text = cat.name;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(formCategoryTypeProvider.notifier).state = cat.type;
      ref.read(selectedIconProvider.notifier).state = cat.icon ?? '📁';
      ref.read(selectedParentIdProvider.notifier).state = cat.parentId;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryType = ref.watch(formCategoryTypeProvider);
    final selectedIcon = ref.watch(selectedIconProvider);
    final isSystem = widget.category?.isSystem ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
        actions: [
          if (isEditing && !isSystem)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mensaje si es categoría del sistema
            if (isSystem) ...[
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Esta es una categoría del sistema. '
                          'Solo puedes modificar el nombre y el icono.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Preview del icono y nombre
            _buildPreviewCard(selectedIcon),
            const SizedBox(height: 24),

            // Selector de tipo (solo si no es sistema y no está editando)
            if (!isSystem && !isEditing) ...[
              _buildTypeSelector(categoryType),
              const SizedBox(height: 16),
            ],

            // Campo de nombre
            _buildNameField(),
            const SizedBox(height: 16),

            // Selector de icono
            _buildIconSelector(selectedIcon),
            const SizedBox(height: 16),

            // Selector de categoría padre (solo para subcategorías)
            if (!isSystem) ...[
              _buildParentSelector(categoryType),
              const SizedBox(height: 32),
            ],

            // Botón guardar
            FilledButton.icon(
              onPressed: _saveCategory,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Actualizar' : 'Crear'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(String icon) {
    final name = _nameController.text.isEmpty
        ? 'Nombre de categoría'
        : _nameController.text;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(String categoryType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de categoría',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'expense',
              label: Text('Gasto'),
              icon: Icon(Icons.arrow_upward),
            ),
            ButtonSegment(
              value: 'income',
              label: Text('Ingreso'),
              icon: Icon(Icons.arrow_downward),
            ),
            ButtonSegment(
              value: 'asset',
              label: Text('Activo'),
              icon: Icon(Icons.account_balance),
            ),
            ButtonSegment(
              value: 'liability',
              label: Text('Pasivo'),
              icon: Icon(Icons.credit_card),
            ),
          ],
          selected: {categoryType},
          onSelectionChanged: (selected) {
            ref.read(formCategoryTypeProvider.notifier).state = selected.first;
            // Limpiar padre al cambiar tipo
            ref.read(selectedParentIdProvider.notifier).state = null;
          },
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Nombre',
        prefixIcon: Icon(Icons.label),
        border: OutlineInputBorder(),
        hintText: 'Ej: Alimentación, Transporte...',
      ),
      onChanged: (_) => setState(() {}), // Actualizar preview
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa un nombre';
        }
        if (value.trim().length < 2) {
          return 'El nombre debe tener al menos 2 caracteres';
        }
        if (value.trim().length > 50) {
          return 'El nombre es muy largo';
        }
        return null;
      },
    );
  }

  Widget _buildIconSelector(String selectedIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icono',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableIcons.map((icon) {
              final isSelected = icon == selectedIcon;
              return InkWell(
                onTap: () {
                  ref.read(selectedIconProvider.notifier).state = icon;
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildParentSelector(String categoryType) {
    final selectedParentId = ref.watch(selectedParentIdProvider);
    final categoriesAsync = ref.watch(categoriesByTypeProvider(categoryType));

    return categoriesAsync.when(
      data: (categories) {
        // Solo mostrar categorías raíz como padres potenciales
        final rootCategories = categories
            .where((c) => c.parentId == null && c.id != widget.category?.id)
            .toList();

        if (rootCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categoría padre (opcional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: selectedParentId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.subdirectory_arrow_right),
                border: OutlineInputBorder(),
                hintText: 'Ninguna (categoría principal)',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Ninguna (categoría principal)'),
                ),
                ...rootCategories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Text(
                          category.icon ?? '📁',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                ref.read(selectedParentIdProvider.notifier).state = value;
              },
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final categoryType = ref.read(formCategoryTypeProvider);
    final selectedIcon = ref.read(selectedIconProvider);
    final parentId = ref.read(selectedParentIdProvider);
    final name = _nameController.text.trim();

    final categoriesDao = ref.read(categoriesDaoProvider);

    try {
      if (isEditing) {
        // Actualizar categoría existente
        final existing = widget.category!;
        await categoriesDao.updateCategory(CategoriesCompanion(
          id: Value(existing.id),
          name: Value(name),
          icon: Value(selectedIcon),
          type: Value(existing.type),
          parentId: Value(existing.parentId),
          level: Value(existing.level),
          sortOrder: Value(existing.sortOrder),
          isActive: Value(existing.isActive),
          isSystem: Value(existing.isSystem),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(DateTime.now()),
        ));
      } else {
        // Crear nueva categoría
        final level = parentId == null ? 0 : 1;
        String? userId;
        try {
          userId = Supabase.instance.client.auth.currentUser?.id;
        } catch (_) {
          userId = null;
        }
        await categoriesDao.insertCategory(CategoriesCompanion(
          id: Value(const Uuid().v4()),
          userId: Value(userId),
          name: Value(name),
          icon: Value(selectedIcon),
          type: Value(categoryType),
          parentId: Value(parentId),
          level: Value(level),
          sortOrder: const Value(0),
          isActive: const Value(true),
          isSystem: const Value(false),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Categoría actualizada' : 'Categoría creada',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta categoría? '
          'Las transacciones asociadas quedarán sin categoría.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final categoriesDao = ref.read(categoriesDaoProvider);

      try {
        await categoriesDao.deleteCategory(widget.category!.id);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoría eliminada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
}
