// Pruebas del widget SignalIndicator.
// Verifica la clasificación de la señal según la precisión horizontal.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/presentation/widgets/signal_indicator.dart';

void main() {
  group('SignalIndicator classification', () {
    testWidgets('accuracy 3.0 muestra "Excelente"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalIndicator(accuracy: 3.0),
          ),
        ),
      );

      expect(find.text('Excelente'), findsOneWidget);
    });

    testWidgets('accuracy 8.0 muestra "Buena"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalIndicator(accuracy: 8.0),
          ),
        ),
      );

      expect(find.text('Buena'), findsOneWidget);
    });

    testWidgets('accuracy 15.0 muestra "Regular"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalIndicator(accuracy: 15.0),
          ),
        ),
      );

      expect(find.text('Regular'), findsOneWidget);
    });

    testWidgets('accuracy 20.0 muestra "Pobre"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalIndicator(accuracy: 20.0),
          ),
        ),
      );

      expect(find.text('Pobre'), findsOneWidget);
    });

    testWidgets('accuracy null muestra "Sin señal"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalIndicator(accuracy: null),
          ),
        ),
      );

      expect(find.text('Sin señal'), findsOneWidget);
    });

    testWidgets('accuracy 0.0 muestra "Sin señal"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignalIndicator(accuracy: 0.0),
          ),
        ),
      );

      expect(find.text('Sin señal'), findsOneWidget);
    });
  });
}
