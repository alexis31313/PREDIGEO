// Pantalla de consentimiento informado de PrediGeo.
// Muestra el texto de docs/consentimiento_informado.md (Ley 1581 de 2012,
// uso académico, confidencialidad) con casilla de aceptación.
// El botón Continuar está deshabilitado hasta aceptar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';

/// Segunda pantalla del flujo de primer uso.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _accepted = false;
  bool _saving = false;

  Future<void> _continue() async {
    if (!_accepted) return;
    setState(() => _saving = true);
    await ref.read(settingsProvider.notifier).acceptConsent();
    if (mounted) context.go('/permission');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consentimiento informado'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consentimiento informado para el uso de datos en investigación',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Título: Evaluación de la precisión de mediciones GNSS en '
                    'dispositivos móviles para el cálculo de áreas y distancias '
                    'en zonas rurales y urbanas.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Institución: Universidad de Putumayo. Investigadores: '
                    'Steve Alexander Calvache Martinez y Luis Alejandro Paz '
                    'Acero. Asesor: Jhon Alexander Gómez.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Propósito (uso académico)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Text(
                    'Evaluar la precisión del GNSS en dispositivos móviles con '
                    'la aplicación PrediGeo para determinar áreas y distancias '
                    'en terrenos rural abierto, rural con vegetación y urbano. '
                    'Los resultados son parte del trabajo de grado (tesis).',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Confidencialidad (Ley 1581 de 2012)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Text(
                    '• Los datos se almacenan exclusivamente en tu dispositivo '
                    '(base de datos local SQLite), sin servidores externos.\n'
                    '• No se recolectan datos personales identificables.\n'
                    '• La participación es voluntaria y puedes retirarte en '
                    'cualquier momento sin consecuencias.\n'
                    '• Los resultados se presentan de forma agregada.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ver el documento completo en docs/consentimiento_informado.md '
                    'del repositorio.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            value: _accepted,
            onChanged: (value) => setState(() => _accepted = value ?? false),
            title: const Text(
              'He leído y acepto el consentimiento informado',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _accepted && !_saving ? _continue : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continuar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
