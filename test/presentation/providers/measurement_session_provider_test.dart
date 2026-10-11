import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/domain/entities/measurement_enums.dart';
import 'package:predigeo/domain/usecases/signal_processing/captured_point.dart';
import 'package:predigeo/presentation/providers/measurement_session_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  MeasurementSessionNotifier notifier() =>
      container.read(measurementSessionProvider.notifier);

  MeasurementSessionState sessionState() =>
      container.read(measurementSessionProvider);

  CapturedPoint captured(
    double latitude,
    double longitude, {
    double accuracy = 4.0,
    double altitude = 430.0,
  }) {
    return CapturedPoint(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      estimatedAccuracy: accuracy,
      sampleCount: 10,
      timestamp: DateTime(2026, 3, 15, 14, 30),
    );
  }

  void addSquare() {
    notifier().addCapturedPoint(captured(1.15380, -76.65100));
    notifier().addCapturedPoint(captured(1.15390, -76.65100));
    notifier().addCapturedPoint(captured(1.15390, -76.65090));
    notifier().addCapturedPoint(captured(1.15380, -76.65090));
  }

  group('estado inicial', () {
    test('arranca como área, sin puntos y sin poder guardar', () {
      expect(sessionState().type, MeasurementType.area);
      expect(sessionState().pointCount, 0);
      expect(sessionState().hasEnoughPoints, isFalse);
      expect(sessionState().canSave, isFalse);
      expect(sessionState().areaM2, isNull);
      expect(sessionState().distanceM, isNull);
      expect(sessionState().avgAccuracyM, 0);
    });
  });

  group('captura de puntos', () {
    test('startCapture marca captura en curso y limpia el error', () {
      notifier().startCapture();
      expect(sessionState().isCapturing, isTrue);
      expect(sessionState().captureProgress, 0);
      expect(sessionState().errorMessage, isNull);
    });

    test('updateCaptureProgress actualiza el progreso acotado', () {
      notifier().startCapture();
      notifier().updateCaptureProgress(0.42);
      expect(sessionState().captureProgress, closeTo(0.42, 1e-9));

      notifier().updateCaptureProgress(2.0);
      expect(sessionState().captureProgress, 1.0);
    });

    test('addCapturedPoint añade el punto, asigna seq y cierra la captura', () {
      notifier().startCapture();
      notifier().addCapturedPoint(captured(1.15, -76.65));

      expect(sessionState().pointCount, 1);
      expect(sessionState().points.first.seq, 0);
      expect(sessionState().points.first.accuracy, 4.0);
      expect(sessionState().isCapturing, isFalse);
    });

    test('removeLastPoint elimina el último y renumera la secuencia', () {
      notifier().addCapturedPoint(captured(1.15, -76.65));
      notifier().addCapturedPoint(captured(1.16, -76.65));
      notifier().addCapturedPoint(captured(1.17, -76.65));

      notifier().removeLastPoint();

      expect(sessionState().pointCount, 2);
      expect(sessionState().points.map((p) => p.seq), [0, 1]);
    });

    test('removeLastPoint sin puntos no hace nada', () {
      notifier().removeLastPoint();
      expect(sessionState().pointCount, 0);
    });

    test('failCapture registra el error y detiene la captura', () {
      notifier().startCapture();
      notifier().failCapture('Punto descartado');

      expect(sessionState().isCapturing, isFalse);
      expect(sessionState().errorMessage, 'Punto descartado');
    });
  });

  group('métricas derivadas', () {
    test('calcula área y perímetro de un polígono de cuatro puntos', () {
      addSquare();

      expect(sessionState().pointCount, 4);
      expect(sessionState().hasEnoughPoints, isTrue);
      expect(sessionState().areaM2, isNotNull);
      expect(sessionState().areaM2!, closeTo(124.0, 5.0));
      expect(sessionState().perimeterM, isNotNull);
      expect(sessionState().perimeterM!, closeTo(44.5, 3.0));
    });

    test('tres puntos ya permiten calcular el área', () {
      notifier().addCapturedPoint(captured(1.15380, -76.65100));
      notifier().addCapturedPoint(captured(1.15390, -76.65100));
      notifier().addCapturedPoint(captured(1.15390, -76.65090));

      expect(sessionState().hasEnoughPoints, isTrue);
      expect(sessionState().areaM2, isNotNull);
      expect(sessionState().areaM2!, greaterThan(0));
    });

    test('el trayecto calcula distancia, no área', () {
      notifier().setType(MeasurementType.path);
      notifier().addCapturedPoint(captured(1.15380, -76.65100));
      notifier().addCapturedPoint(captured(1.15390, -76.65100));

      expect(sessionState().areaM2, isNull);
      expect(sessionState().perimeterM, isNull);
      expect(sessionState().distanceM, isNotNull);
      expect(sessionState().distanceM!, closeTo(11.13, 1.0));
    });

    test('average de precisión de los puntos', () {
      notifier().addCapturedPoint(captured(1.15, -76.65, accuracy: 3.0));
      notifier().addCapturedPoint(captured(1.16, -76.65, accuracy: 6.0));
      notifier().addCapturedPoint(captured(1.17, -76.65, accuracy: 9.0));

      expect(sessionState().avgAccuracyM, closeTo(6.0, 1e-9));
    });

    test('expone estadísticas de relieve', () {
      notifier().addCapturedPoint(captured(1.15, -76.65, altitude: 100));
      notifier().addCapturedPoint(captured(1.16, -76.65, altitude: 130));

      expect(sessionState().elevationStats.minAltitude, 100);
      expect(sessionState().elevationStats.maxAltitude, 130);
    });
  });

  group('guardado y reinicio', () {
    test('canSave exige nombre y puntos suficientes', () {
      addSquare();
      expect(sessionState().canSave, isFalse);

      notifier().setName('Lote de prueba');
      expect(sessionState().canSave, isTrue);
    });

    test('clearPoints conserva tipo y categoría', () {
      addSquare();
      notifier().setCategory(MeasurementCategory.urban);
      notifier().clearPoints();

      expect(sessionState().pointCount, 0);
      expect(sessionState().type, MeasurementType.area);
      expect(sessionState().category, MeasurementCategory.urban);
    });

    test('setCategory(null) limpia la categoría', () {
      notifier().setCategory(MeasurementCategory.ruralOpen);
      notifier().setCategory(null);
      expect(sessionState().category, isNull);
    });

    test('reset vuelve al estado inicial', () {
      addSquare();
      notifier().setName('x');
      notifier().reset();

      expect(sessionState().pointCount, 0);
      expect(sessionState().name, '');
      expect(sessionState().type, MeasurementType.area);
    });
  });
}
