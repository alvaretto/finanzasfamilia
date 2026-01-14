import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/providers/auth_provider.dart';
import 'main_shell.dart';

/// Pantalla de inicio de sesión
/// El manejo de deep links OAuth está centralizado en main.dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  /// Navega directamente al home después del login
  /// Con arquitectura online-first, no necesitamos pantalla de recuperación
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider.notifier).signInWithGoogle();
      // La navegación se maneja automáticamente por el listener de authState
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado. Por favor, intenta de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('cancelled') || message.contains('canceled')) {
      return 'Inicio de sesión cancelado';
    }
    if (message.contains('network') || message.contains('connection')) {
      return 'Error de conexión. Verifica tu internet.';
    }
    if (message.contains('invalid')) {
      return 'Credenciales inválidas';
    }
    return e.message;
  }

  Future<void> _continueAsGuest() async {
    // Permitir uso sin autenticación (modo offline completo)
    _navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de autenticación para navegación automática
    ref.listen(authStateProvider, (previous, next) {
      if (next == AuthStatus.authenticated && mounted) {
        // Ir directamente al home - arquitectura online-first
        _navigateToHome();
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo y título
              _LogoSection(colorScheme: colorScheme, theme: theme),
              const Spacer(),
              // Botones de login
              _LoginButtons(
                isLoading: _isLoading,
                onGoogleSignIn: _signInWithGoogle,
                onContinueAsGuest: _continueAsGuest,
                colorScheme: colorScheme,
              ),
              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorMessage(message: _errorMessage!),
              ],
              const SizedBox(height: 24),
              // Términos y condiciones
              _TermsText(colorScheme: colorScheme, theme: theme),
              SizedBox(height: size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _LogoSection({
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Finanzas Familiares',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Controla tus finanzas de forma simple',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        // Features
        _FeatureList(colorScheme: colorScheme),
      ],
    );
  }
}

class _FeatureList extends StatelessWidget {
  final ColorScheme colorScheme;

  const _FeatureList({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeatureItem(
          icon: Icons.offline_bolt,
          text: 'Funciona sin internet',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _FeatureItem(
          icon: Icons.sync,
          text: 'Sincronización automática',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _FeatureItem(
          icon: Icons.smart_toy,
          text: 'Asistente IA incluido',
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

class _LoginButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onContinueAsGuest;
  final ColorScheme colorScheme;

  const _LoginButtons({
    required this.isLoading,
    required this.onGoogleSignIn,
    required this.onContinueAsGuest,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign In
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: isLoading ? null : onGoogleSignIn,
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const _GoogleIcon(),
            label: Text(isLoading ? 'Conectando...' : 'Continuar con Google'),
          ),
        ),
        const SizedBox(height: 16),
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 16),
        // Continue as guest
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onContinueAsGuest,
            icon: const Icon(Icons.person_outline),
            label: const Text('Continuar sin cuenta'),
          ),
        ),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // Icono simple de Google usando Material Icons
    return const Icon(Icons.g_mobiledata, size: 24);
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _TermsText({
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'Al continuar, aceptas nuestros ',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(
            text: 'Términos de Servicio',
            style: TextStyle(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' y '),
          TextSpan(
            text: 'Política de Privacidad',
            style: TextStyle(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
