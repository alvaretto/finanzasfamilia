import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_provider.dart';
import '../../application/providers/onboarding_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

/// Pantalla de splash que verifica el estado de autenticación
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    debugPrint('[SPLASH] _checkAuthAndNavigate iniciado');
    try {
      // Esperar mínimo 2 segundos para mostrar el splash
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Verificar si es primera vez
      debugPrint('[SPLASH] Verificando isFirstTimeUser...');
      final isFirstTime = await ref.read(isFirstTimeUserProvider.future);
      debugPrint('[SPLASH] isFirstTime=$isFirstTime');

      if (!mounted) return;

      if (isFirstTime) {
        debugPrint('[SPLASH] Primera vez, navegando a Onboarding');
        _navigateTo(OnboardingScreen(
          onComplete: () => _onOnboardingComplete(),
        ));
        return;
      }

      debugPrint('[SPLASH] No es primera vez, verificando auth...');
      _navigateBasedOnAuth();
    } catch (e) {
      debugPrint('[SPLASH] ERROR: $e');
      // En caso de error, ir directo al login
      if (mounted) {
        _navigateTo(const LoginScreen());
      }
    }
  }

  void _onOnboardingComplete() {
    // Este callback se llama desde OnboardingScreen después de completar.
    // Como usamos pushReplacement para navegar a OnboardingScreen,
    // este widget (SplashScreen) ya está disposed y no podemos usar ref.
    // La navegación post-onboarding ahora se maneja en OnboardingScreen.
  }

  void _navigateBasedOnAuth() {
    if (!mounted) return;

    final authStatus = ref.read(authStateProvider);

    debugPrint('[SPLASH] _navigateBasedOnAuth: authStatus=$authStatus');

    if (authStatus == AuthStatus.authenticated) {
      // Usuario autenticado - ir directo al home
      // Arquitectura online-first: no necesita pantalla de recuperación
      debugPrint('[SPLASH] Navegando a MainShell');
      _navigateTo(const MainShell());
    } else {
      debugPrint('[SPLASH] No autenticado, navegando a LoginScreen');
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Icono
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 32),
              // Nombre de la app
              Text(
                'Finanzas Familiares',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu asistente financiero personal',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 48),
              // Indicador de carga
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
