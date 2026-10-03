// Pantalla de nueva medición - placeholder en desarrollo.

import 'package:flutter/material.dart';

class MeasureScreen extends StatelessWidget {
  const MeasureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Medición'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Pantalla de medición en desarrollo',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
