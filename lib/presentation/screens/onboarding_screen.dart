import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_provider.dart';
import '../../application/providers/onboarding_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Pantalla de onboarding para nuevos usuarios
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Callback cuando el onboarding se completa
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  static const _totalPages = 4;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: 'Bienvenido a',
      subtitle: 'Finanzas Familiares',
      description:
          'Tu asistente financiero personal adaptado a la realidad colombiana.',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF1B5E20),
    ),
    _OnboardingPageData(
      title: 'Control Total',
      subtitle: 'de tus finanzas',
      description:
          'Registra gastos, ingresos y visualiza tu situación financiera en tiempo real.',
      icon: Icons.pie_chart,
      color: Color(0xFF0D47A1),
      features: [
        _FeatureItem(Icons.offline_bolt, 'Funciona sin internet'),
        _FeatureItem(Icons.sync, 'Sincronización automática'),
        _FeatureItem(Icons.smart_toy, 'Asistente IA incluido'),
      ],
    ),
    _OnboardingPageData(
      title: 'Tus Cuentas',
      subtitle: 'organizadas',
      description:
          'Configura tus cuentas bancarias, billeteras digitales y efectivo.',
      icon: Icons.account_balance,
      color: Color(0xFF4A148C),
      accounts: [
        _AccountExample('Nequi', '💜', Color(0xFF6B2D8B)),
        _AccountExample('Davivienda', '🔴', Color(0xFFE53935)),
        _AccountExample('Efectivo', '💵', Color(0xFF43A047)),
      ],
    ),
    _OnboardingPageData(
      title: 'Todo Listo',
      subtitle: 'para comenzar',
      description:
          'Empieza a registrar tus transacciones y toma el control de tu dinero.',
      icon: Icons.rocket_launch,
      color: Color(0xFFE65100),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(onboardingServiceProvider).completeOnboarding();

      if (!mounted) return;

      // Navegar basado en el estado de autenticación
      _navigateBasedOnAuth();

      // Notificar al parent (por compatibilidad, aunque ahora navegamos aquí)
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al completar. Intenta de nuevo.'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _completeOnboarding,
            ),
          ),
        );
      }
    }
  }

  void _navigateBasedOnAuth() {
    final authStatus = ref.read(authStateProvider);

    final Widget destination = authStatus == AuthStatus.authenticated
        ? const MainShell()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón Omitir
            if (!isLastPage)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Omitir'),
                ),
              )
            else
              const SizedBox(height: 48),

            // PageView con las páginas
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _totalPages,
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),

            // Indicadores de página
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => _PageIndicator(isActive: index == _currentPage),
                ),
              ),
            ),

            // Botón de acción
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _nextPage,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLastPage ? 'Comenzar' : 'Siguiente'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Datos de una página de onboarding
class _OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<_FeatureItem>? features;
  final List<_AccountExample>? accounts;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.features,
    this.accounts,
  });
}

/// Item de característica
class _FeatureItem {
  final IconData icon;
  final String text;

  const _FeatureItem(this.icon, this.text);
}

/// Ejemplo de cuenta
class _AccountExample {
  final String name;
  final String emoji;
  final Color color;

  const _AccountExample(this.name, this.emoji, this.color);
}

/// Widget de página de onboarding
class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Icono principal
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: data.color,
            ),
          ),
          const SizedBox(height: 40),

          // Título
          Text(
            data.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            data.subtitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: data.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Descripción
          Text(
            data.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Características (si las hay)
          if (data.features != null) ...[
            ...data.features!.map((f) => _FeatureRow(feature: f)),
          ],

          // Cuentas de ejemplo (si las hay)
          if (data.accounts != null) ...[
            ...data.accounts!.map((a) => _AccountRow(account: a)),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Fila de característica
class _FeatureRow extends StatelessWidget {
  final _FeatureItem feature;

  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            feature.icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            feature.text,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Fila de cuenta de ejemplo
class _AccountRow extends StatelessWidget {
  final _AccountExample account;

  const _AccountRow({required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: account.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: account.color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(account.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              account.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: account.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de página
class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
