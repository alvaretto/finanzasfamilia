import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/providers/providers.dart';
import 'shared/widgets/app_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: FinanzasFamiliaresApp(),
    ),
  );
}

class FinanzasFamiliaresApp extends StatelessWidget {
  const FinanzasFamiliaresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBootstrap();
  }
}

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializationAsync = ref.watch(appInitializationProvider);

    return initializationAsync.when(
      data: (result) {
        if (result.hasError) {
          return MaterialApp(
            title: 'Finanzas Familiares',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: AppErrorScreen(
              message: result.errorMessage!,
              onRetry: () {
                ref.invalidate(appInitializationProvider);
              },
            ),
          );
        }

        final router = ref.watch(routerProvider);
        final themeMode = ref.watch(themeModeProvider);

        return MaterialApp.router(
          title: 'Finanzas Familiares',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: router,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'CO'),
            Locale('es', 'MX'),
            Locale('es'),
            Locale('en', 'US'),
            Locale('pt', 'BR'),
          ],
          locale: const Locale('es', 'CO'),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child!,
            );
          },
        );
      },
      loading: () {
        return MaterialApp(
          title: 'Finanzas Familiares',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, stackTrace) {
        return MaterialApp(
          title: 'Finanzas Familiares',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: AppErrorScreen(
            message: 'Error inesperado: $error',
            onRetry: () {
              ref.invalidate(appInitializationProvider);
            },
          ),
        );
      },
    );
  }
}
