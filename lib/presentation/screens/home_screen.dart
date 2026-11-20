import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/connectivity_provider.dart';
import '../providers/gps_state_notifier.dart';
import '../widgets/signal_indicator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConnection());
  }

  /// Al iniciar la aplicación, intenta conectarse a internet. Si no logra
  /// establecer la conexión, muestra un diálogo que ofrece continuar sin
  /// conexión o reintentar la conexión.
  Future<void> _checkConnection() async {
    var isOnline = true;
    try {
      isOnline = await ref.read(isConnectedProvider.future);
    } catch (_) {
      // Ante un error consultando la red se asume modo sin conexión.
      isOnline = false;
    }

    if (!mounted) return;
    if (isOnline) return;

    final proceedOffline = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sin conexión a internet'),
        content: const Text(
          'No se pudo establecer conexión con internet. Puedes continuar '
          'usando PrediGeo sin conexión o intentar reconectar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Intentar reconectar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Usar sin internet'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (proceedOffline == true) {
      // El usuario eligió operar sin internet: la app continúa en modo offline.
      return;
    }
    // El usuario eligió "Intentar reconectar": se vuelve a verificar.
    await _checkConnection();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isOnline = ref.watch(isOnlineProvider);
    final reading = ref.watch(gpsReadingStreamProvider).asData?.value;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary,
                      Color.lerp(colors.primary, colors.tertiary, 0.28)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: colors.onPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        Icons.terrain,
                        size: 38,
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'PrediGeo',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(color: colors.onPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Medición de terrenos con GPS',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colors.onPrimary.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _StatusPill(
                    icon: Icons.satellite_alt,
                    child: SignalIndicator(
                      accuracy: reading?.horizontalAccuracy,
                    ),
                  ),
                  _StatusPill(
                    icon: isOnline ? Icons.cloud_done_outlined : Icons.wifi_off,
                    child: Text(
                      isOnline ? 'Conectado' : 'Desconectado',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _StaggeredCard(
                index: 0,
                child: _PrimaryActionCard(
                  title: 'Nueva Medición',
                  subtitle: 'Mide un área o registra un trayecto',
                  onTap: () => context.push('/measure'),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    _SecondaryActionCard(
                      icon: Icons.history,
                      title: 'Historial',
                      subtitle: 'Mediciones guardadas',
                      onTap: () => context.push('/history'),
                    ),
                    _SecondaryActionCard(
                      icon: Icons.assessment_outlined,
                      title: 'Evaluación',
                      subtitle: 'Revisa tus resultados',
                      onTap: () => context.push('/evaluation'),
                    ),
                  ];
                  if (constraints.maxWidth >= 460) {
                    return Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(
                            child: _StaggeredCard(
                              index: i + 1,
                              child: cards[i],
                            ),
                          ),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _StaggeredCard(index: i + 1, child: cards[i]),
                      ],
                    ],
                  );
                },
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                _StaggeredCard(
                  index: 3,
                  child: _SecondaryActionCard(
                    icon: Icons.satellite_alt,
                    title: 'GPS Debug',
                    subtitle: 'Ver señal GPS en tiempo real',
                    onTap: () => context.push('/gps-debug'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _StatusPill({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          child,
        ],
      ),
    );
  }
}

class _StaggeredCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredCard({required this.index, required this.child});

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.index * 90), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.08),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 360),
        child: widget.child,
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Icon(Icons.add_location_alt, size: 36, color: colors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 28, color: colors.secondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
