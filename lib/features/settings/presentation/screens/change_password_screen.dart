import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);

      // Supabase no requiere verificar contraseña actual para updatePassword
      // Solo necesita el nuevo password
      await repository.updatePassword(_newPasswordController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar contraseña: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    // Verificar al menos una letra y un número
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Debe contener al menos una letra';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isGoogleAuth = user?.appMetadata['provider'] == 'google';

    // No permitir cambio de contraseña para Google Sign-In
    if (isGoogleAuth) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cambiar Contraseña')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No disponible',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tu cuenta está vinculada con Google Sign-In.\nGestiona tu contraseña desde tu cuenta de Google.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _changePassword,
              child: const Text('Guardar'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Info header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tu contraseña debe tener al menos 8 caracteres, incluyendo letras y números.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Contraseña actual (opcional - Supabase no la requiere)
            TextFormField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Contraseña Actual (Opcional)',
                hintText: 'Ingresa tu contraseña actual',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                  },
                ),
              ),
              obscureText: _obscureCurrentPassword,
            ),
            const SizedBox(height: AppSpacing.md),

            // Nueva contraseña
            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña',
                hintText: 'Mínimo 8 caracteres',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                ),
              ),
              obscureText: _obscureNewPassword,
              validator: _validatePassword,
            ),
            const SizedBox(height: AppSpacing.md),

            // Confirmar contraseña
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirmar Nueva Contraseña',
                hintText: 'Repite tu contraseña',
                prefixIcon: Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirma tu contraseña';
                }
                if (value != _newPasswordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Indicadores de fortaleza
            _buildPasswordStrengthIndicators(),
            const SizedBox(height: AppSpacing.xl),

            // Botón guardar
            FilledButton(
              onPressed: _isLoading ? null : _changePassword,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cambiar Contraseña'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Información adicional
            Text(
              'Después de cambiar tu contraseña, tendrás que volver a iniciar sesión.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicators() {
    final password = _newPasswordController.text;
    final hasMinLength = password.length >= 8;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requisitos de Contraseña',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildRequirement('Al menos 8 caracteres', hasMinLength),
        _buildRequirement('Contiene letras', hasLetter),
        _buildRequirement('Contiene números', hasNumber),
        _buildRequirement('Caracteres especiales (recomendado)', hasSpecialChar, optional: true),
      ],
    );
  }

  Widget _buildRequirement(String text, bool met, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: met
                ? AppColors.success
                : optional
                    ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: met
                        ? AppColors.success
                        : optional
                            ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.outline,
                    decoration: met ? TextDecoration.lineThrough : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
