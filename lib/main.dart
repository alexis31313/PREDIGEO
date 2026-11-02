import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: PrediGeoApp(),
    ),
  );
}

class PrediGeoApp extends ConsumerWidget {
  const PrediGeoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El enrutador maneja la pantalla inicial: su redirect decide si se debe
    // mostrar el onboarding (primera apertura, persistido en SharedPreferences)
    // o ir directamente a la pantalla principal.
    return MaterialApp.router(
      title: 'PrediGeo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
