// Pantalla de bienvenida de PrediGeo.
// PageView de 3 páginas con indicadores y botón Omitir.
// Se muestra solo la primera vez (bandera en shared_preferences).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';

/// Primera pantalla del flujo de primer uso.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/consent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido a PrediGeo'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Omitir'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (index) => setState(() => _page = index),
              children: const [
                _OnboardingPage(
                  icon: Icons.terrain,
                  title: '¿Qué hace PrediGeo?',
                  description:
                      'Mide áreas y trayectos de terrenos con el GPS de tu '
                      'teléfono. Captura puntos en campo, calcula el área con '
                      'la fórmula de Gauss y guarda el historial sin Internet.',
                ),
                _OnboardingPage(
                  icon: Icons.cloud_off,
                  title: 'Funciona sin conexión',
                  description:
                      'PrediGeo es offline-first: la captura, el cálculo y el '
                      'almacenamiento son 100 % locales. Solo necesitas el '
                      'GPS activado, no datos ni wifi.',
                ),
                _OnboardingPage(
                  icon: Icons.gps_fixed,
                  title: 'Cómo obtener buena precisión',
                  description:
                      'Sal al exterior con vista despejada del cielo, espera '
                      'a que la precisión sea menor a 8 m, camina pausado y '
                      'captura al menos 10 muestras por punto.',
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_page > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Atrás'),
                    ),
                  ),
                if (_page > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _page == 2
                        ? _finish
                        : () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                    child: Text(_page == 2 ? 'Empezar' : 'Siguiente'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
