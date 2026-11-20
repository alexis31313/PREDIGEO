import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla de bienvenida paso a paso que se muestra la primera vez que se
/// inicia la aplicación. El usuario puede deslizar las páginas o tocar
/// "Empezar" para continuar directamente a la pantalla principal.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  /// Los pasos del onboarding: título, subtítulo y una breve descripción.
  static const steps = [
    {
      'title': 'Nueva Medición',
      'subtitle':
          'Selecciona Área o Trayecto y la app capturará puntos GPS cada 20 segundos de forma automática, o los capturarás manualmente. El mapa se centrará en Mocoa (1.15, -76.65) si no hay puntos.',
    },
    {
      'title': 'Historial',
      'subtitle':
          'Consulta todas las mediciones guardadas localmente en tu dispositivo. Pulsa sobre una para ver su detalle, resultados y evaluaciones de campo.',
    },
    {
      'title': 'Evaluación',
      'subtitle':
          'Revisa estadísticas globales (área total, distancia recorrida, promedio) y las evaluaciones de campo comparando tus resultados contra valores de referencia conocidos.',
    },
    {
      'title': 'Modo Sin Conexión',
      'subtitle':
          'Todas las funcionalidades funcionan sin internet: captura de puntos, cálculo de área/distancia, mapa de relieve OSM y exportación. Los datos se guardan en SQLite local.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: steps.map((step) => _OnboardingStep(title: step['title']!, subtitle: step['subtitle']!)).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            // Marcar visto en SharedPreferences para la próxima apertura.
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('onboarding_seen', true);
            // Navegar a la pantalla principal.
            if (context.mounted) {
              context.go('/');
            }
          },
          child: const Text('Empezar'),
        ),
      ),
    );
  }
}

/// Una sola tarjeta de paso del onboarding.
class _OnboardingStep extends StatelessWidget {
  final String title;
  final String subtitle;

  const _OnboardingStep({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.start,
          ),
          const Spacer(),
          // Ícono representativo pequeño.
          Icon(
            _iconForStep(title),
            size: 64,
            color: colors.primary,
          ),
        ],
      ),
    );
  }

  /// Devuelve un ícono representativo según el título del paso.
  IconData _iconForStep(String title) {
    switch (title) {
      case 'Nueva Medición':
        return Icons.add_location_alt;
      case 'Historial':
        return Icons.history;
      case 'Evaluación':
        return Icons.assessment;
      case 'Modo Sin Conexión':
        return Icons.wifi_off;
      default:
        return Icons.help;
    }
  }
}
