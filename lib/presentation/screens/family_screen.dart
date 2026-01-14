import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/family_provider.dart';
import '../../domain/services/family_service.dart';

/// Pantalla de gestión de familias
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familiesAsync = ref.watch(watchUserFamiliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Familias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Unirse con código',
            onPressed: () => _showJoinByCodeDialog(context, ref),
          ),
        ],
      ),
      body: familiesAsync.when(
        data: (families) => families.isEmpty
            ? _buildEmptyState(context, ref)
            : _buildFamilyList(context, ref, families),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFamilySheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Familia'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin familias',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una familia para compartir finanzas con tus seres queridos',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateFamilySheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Crear Familia'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showJoinByCodeDialog(context, ref),
              icon: const Icon(Icons.qr_code),
              label: const Text('Unirse con código'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyList(
    BuildContext context,
    WidgetRef ref,
    List<FamilyData> families,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: families.length,
      itemBuilder: (context, index) {
        final family = families[index];
        return _FamilyCard(
          family: family,
          onTap: () => _navigateToFamilyDetail(context, ref, family),
        );
      },
    );
  }

  void _showCreateFamilySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CreateFamilySheet(ref: ref),
    );
  }

  void _showJoinByCodeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _JoinByCodeDialog(ref: ref),
    );
  }

  void _navigateToFamilyDetail(
    BuildContext context,
    WidgetRef ref,
    FamilyData family,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FamilyDetailScreen(familyId: family.id),
      ),
    );
  }
}

/// Tarjeta de familia
class _FamilyCard extends StatelessWidget {
  final FamilyData family;
  final VoidCallback onTap;

  const _FamilyCard({required this.family, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: family.color != null
              ? Color(int.parse('0xFF${family.color!.replaceAll('#', '')}'))
              : Theme.of(context).colorScheme.primaryContainer,
          radius: 28,
          child: Text(
            family.icon ?? family.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          family.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: family.description != null
            ? Text(
                family.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Sheet para crear una nueva familia
class _CreateFamilySheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _CreateFamilySheet({required this.ref});

  @override
  ConsumerState<_CreateFamilySheet> createState() => _CreateFamilySheetState();
}

class _CreateFamilySheetState extends ConsumerState<_CreateFamilySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedIcon = '👨‍👩‍👧‍👦';
  String _selectedColor = '#4CAF50';
  bool _isLoading = false;

  final _icons = [
    '👨‍👩‍👧‍👦',
    '👨‍👩‍👧',
    '👨‍👩‍👦',
    '👪',
    '🏠',
    '❤️',
    '💰',
    '🏦'
  ];
  final _colors = [
    '#4CAF50',
    '#2196F3',
    '#9C27B0',
    '#FF9800',
    '#E91E63',
    '#00BCD4',
    '#795548',
    '#607D8B'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crear Familia',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la familia',
                  hintText: 'Ej: Familia García',
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej: Finanzas del hogar principal',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Text(
                'Icono',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _icons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  final colorValue =
                      Color(int.parse('0xFF${color.replaceAll('#', '')}'));
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorValue.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _createFamily,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear Familia'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(familyNotifierProvider.notifier).createFamily(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            icon: _selectedIcon,
            color: _selectedColor,
          );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Familia creada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Sheet para editar una familia existente
class _EditFamilySheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final FamilyData family;

  const _EditFamilySheet({required this.ref, required this.family});

  @override
  ConsumerState<_EditFamilySheet> createState() => _EditFamilySheetState();
}

class _EditFamilySheetState extends ConsumerState<_EditFamilySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedIcon;
  late String _selectedColor;
  bool _isLoading = false;

  final _icons = [
    '👨‍👩‍👧‍👦',
    '👨‍👩‍👧',
    '👨‍👩‍👦',
    '👪',
    '🏠',
    '❤️',
    '💰',
    '🏦'
  ];
  final _colors = [
    '#4CAF50',
    '#2196F3',
    '#9C27B0',
    '#FF9800',
    '#E91E63',
    '#00BCD4',
    '#795548',
    '#607D8B'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.family.name);
    _descriptionController =
        TextEditingController(text: widget.family.description ?? '');
    _selectedIcon = widget.family.icon ?? '👨‍👩‍👧‍👦';
    _selectedColor = widget.family.color ?? '#4CAF50';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Editar Familia',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la familia',
                  hintText: 'Ej: Familia García',
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej: Finanzas del hogar principal',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Text(
                'Icono',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _icons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  final colorValue =
                      Color(int.parse('0xFF${color.replaceAll('#', '')}'));
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorValue.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _updateFamily,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(familyNotifierProvider.notifier).updateFamily(
            familyId: widget.family.id,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            icon: _selectedIcon,
            color: _selectedColor,
          );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Familia actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Diálogo para unirse con código
class _JoinByCodeDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _JoinByCodeDialog({required this.ref});

  @override
  ConsumerState<_JoinByCodeDialog> createState() => _JoinByCodeDialogState();
}

class _JoinByCodeDialogState extends ConsumerState<_JoinByCodeDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unirse a Familia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ingresa el código de invitación que te compartieron'),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código',
              hintText: 'ABCD1234',
              prefixIcon: Icon(Icons.key),
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 12,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _joinFamily,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unirse'),
        ),
      ],
    );
  }

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(familyNotifierProvider.notifier).joinByCode(code);

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te has unido a la familia')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Pantalla de detalle de una familia
class FamilyDetailScreen extends ConsumerWidget {
  final String familyId;

  const FamilyDetailScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyWithMembersProvider(familyId));

    return familyAsync.when(
      data: (familyData) {
        if (familyData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Familia')),
            body: const Center(child: Text('Familia no encontrada')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(familyData.family.name),
            actions: [
              if (familyData.isAdmin)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showFamilySettings(context, ref, familyData),
                ),
            ],
          ),
          body: _FamilyDetailBody(familyData: familyData),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showFamilySettings(
    BuildContext context,
    WidgetRef ref,
    FamilyWithMembersData familyData,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Generar código de invitación'),
              onTap: () async {
                Navigator.pop(context);
                await _generateAndShowCode(context, ref, familyData.family.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Invitar por email'),
              onTap: () {
                Navigator.pop(context);
                _showInviteByEmailDialog(context, ref, familyData.family.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar familia'),
              onTap: () {
                Navigator.pop(context);
                _showEditFamilySheet(context, ref, familyData.family);
              },
            ),
            if (familyData.isOwner)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar familia',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _confirmDeleteFamily(context, ref, familyData.family);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShowCode(
    BuildContext context,
    WidgetRef ref,
    String familyId,
  ) async {
    try {
      final code = await ref
          .read(familyNotifierProvider.notifier)
          .generateInviteCode(familyId);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Código de Invitación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Comparte este código con quien quieras invitar:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    code,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                },
                child: const Text('Copiar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showInviteByEmailDialog(
    BuildContext context,
    WidgetRef ref,
    String familyId,
  ) {
    final emailController = TextEditingController();
    String selectedRole = 'member';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invitar por Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  DropdownMenuItem(value: 'member', child: Text('Miembro')),
                  DropdownMenuItem(value: 'viewer', child: Text('Solo lectura')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRole = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                try {
                  await ref.read(familyNotifierProvider.notifier).inviteByEmail(
                        familyId: familyId,
                        email: email,
                        role: selectedRole,
                      );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invitación enviada a $email')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Invitar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFamilySheet(
    BuildContext context,
    WidgetRef ref,
    FamilyData family,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EditFamilySheet(ref: ref, family: family),
    );
  }

  Future<void> _confirmDeleteFamily(
    BuildContext context,
    WidgetRef ref,
    FamilyData family,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Familia'),
        content: Text(
          '¿Estás seguro de eliminar "${family.name}"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(familyNotifierProvider.notifier).deleteFamily(family.id);
        if (context.mounted) {
          Navigator.of(context).pop(); // Volver a la lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Familia eliminada')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

}

/// Cuerpo del detalle de familia
class _FamilyDetailBody extends ConsumerWidget {
  final FamilyWithMembersData familyData;

  const _FamilyDetailBody({required this.familyData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(watchFamilyMembersProvider(familyData.family.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info de la familia
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: familyData.family.color != null
                          ? Color(int.parse(
                              '0xFF${familyData.family.color!.replaceAll('#', '')}'))
                          : Theme.of(context).colorScheme.primaryContainer,
                      radius: 32,
                      child: Text(
                        familyData.family.icon ??
                            familyData.family.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            familyData.family.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (familyData.family.description != null)
                            Text(
                              familyData.family.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.people,
                      label: '${familyData.memberCount} miembros',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.badge,
                      label: _roleLabel(familyData.currentUserMember?.role),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Miembros
        Text(
          'Miembros',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        membersAsync.when(
          data: (members) => Column(
            children: members
                .map((member) => _MemberTile(
                      member: member,
                      isCurrentUser:
                          member.userId == familyData.currentUserMember?.userId,
                      canManage: familyData.canManageMembers,
                      onRemove: () => _removeMember(context, ref, member),
                      onChangeRole: (role) =>
                          _changeRole(context, ref, member, role),
                    ))
                .toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'owner':
        return 'Dueño';
      case 'admin':
        return 'Administrador';
      case 'member':
        return 'Miembro';
      case 'viewer':
        return 'Solo lectura';
      default:
        return 'Miembro';
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    FamilyMemberData member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text('¿Eliminar al usuario ${member.userId.substring(0, 8)}...?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(familyNotifierProvider.notifier)
          .removeMember(familyData.family.id, member.id);
    }
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    FamilyMemberData member,
    String role,
  ) async {
    await ref
        .read(familyNotifierProvider.notifier)
        .changeMemberRole(familyData.family.id, member.id, role);
  }
}

/// Chip de información
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

/// Tile de miembro
class _MemberTile extends StatelessWidget {
  final FamilyMemberData member;
  final bool isCurrentUser;
  final bool canManage;
  final VoidCallback onRemove;
  final Function(String) onChangeRole;

  const _MemberTile({
    required this.member,
    required this.isCurrentUser,
    required this.canManage,
    required this.onRemove,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            member.userId.substring(0, 1).toUpperCase(),
          ),
        ),
        title: Row(
          children: [
            Text('Usuario ${member.userId.substring(0, 8)}...'),
            if (isCurrentUser)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Chip(
                  label: Text('Tú', style: TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        subtitle: Text(_roleLabel(member.role)),
        trailing: canManage && !isCurrentUser && member.role != 'owner'
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    onRemove();
                  } else {
                    onChangeRole(value);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'admin',
                    child: Text('Hacer administrador'),
                  ),
                  const PopupMenuItem(
                    value: 'member',
                    child: Text('Hacer miembro'),
                  ),
                  const PopupMenuItem(
                    value: 'viewer',
                    child: Text('Solo lectura'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'remove',
                    child:
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return '👑 Dueño';
      case 'admin':
        return '⚙️ Administrador';
      case 'member':
        return '👤 Miembro';
      case 'viewer':
        return '👁️ Solo lectura';
      default:
        return '👤 Miembro';
    }
  }
}
