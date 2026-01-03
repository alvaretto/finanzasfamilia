import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/family_model.dart';
import '../providers/family_provider.dart';
import '../widgets/create_family_sheet.dart';
import '../widgets/join_family_sheet.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyProvider);

    // Escuchar mensajes
    ref.listen<FamilyState>(familyProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(familyProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Familias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(familyProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading && state.families.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.families.isEmpty
              ? _buildEmptyState(context, ref)
              : RefreshIndicator(
                  onRefresh: () => ref.read(familyProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.families.length,
                    itemBuilder: (context, index) {
                      final family = state.families[index];
                      return _FamilyCard(family: family);
                    },
                  ),
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            onPressed: () => _showJoinSheet(context),
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => _showCreateSheet(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sin familias',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Crea una familia para compartir\nfinanzas con tus seres queridos',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showJoinSheet(context),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Unirse'),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => _showCreateSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateFamilySheet(),
    );
  }

  void _showJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const JoinFamilySheet(),
    );
  }
}

class _FamilyCard extends ConsumerWidget {
  final FamilyModel family;

  const _FamilyCard({required this.family});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authProvider).user?.id;
    final isOwner = family.isOwner(currentUserId ?? '');
    final myMember = family.getMember(currentUserId ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showFamilyDetails(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.family_restroom,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${family.memberCount} miembro${family.memberCount != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (myMember != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(myMember.role).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        myMember.role.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getRoleColor(myMember.role),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (isOwner && family.inviteCode != null) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      Icons.vpn_key,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Código: ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      family.inviteCode!.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: family.inviteCode!.toUpperCase()),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código copiado')),
                        );
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return AppColors.primary;
      case FamilyRole.admin:
        return AppColors.income;
      case FamilyRole.member:
        return AppColors.info;
      case FamilyRole.viewer:
        return Colors.grey;
    }
  }

  void _showFamilyDetails(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authProvider).user?.id;
    final isOwner = family.isOwner(currentUserId ?? '');
    final myMember = family.getMember(currentUserId ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      family.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        Navigator.pop(context);
                        if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar familia'),
                              content: const Text(
                                '¿Estás seguro? Se eliminarán todos los datos compartidos.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(familyProvider.notifier).deleteFamily(family.id);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppColors.error),
                              SizedBox(width: AppSpacing.sm),
                              Text('Eliminar familia'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Miembros
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: family.members.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        'Miembros (${family.memberCount})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    );
                  }
                  final member = family.members[index - 1];
                  final isSelf = member.userId == currentUserId;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.avatarUrl != null
                          ? NetworkImage(member.avatarUrl!)
                          : null,
                      child: member.avatarUrl == null
                          ? Text(
                              (member.displayName ?? 'U')[0].toUpperCase(),
                            )
                          : null,
                    ),
                    title: Text(
                      member.displayName ?? 'Usuario',
                      style: TextStyle(
                        fontWeight: isSelf ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: Text(member.role.displayName),
                    trailing: isSelf
                        ? const Chip(label: Text('Tú'))
                        : myMember?.role.canManageMembers == true &&
                                member.role != FamilyRole.owner
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'remove') {
                                    ref
                                        .read(familyProvider.notifier)
                                        .removeMember(member.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              )
                            : null,
                  );
                },
              ),
            ),
            // Botón salir
            if (!isOwner)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    ref.read(familyProvider.notifier).leaveFamily(family.id);
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Salir de la familia'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
