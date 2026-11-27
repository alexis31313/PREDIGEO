import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/data/datasources/interior_points_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fixtures.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('guarda y recupera los puntos interiores de una medición', () async {
    final store = InteriorPointsStore();
    final points = [
      buildPoint(seq: 0, latitude: 1.15390, longitude: -76.65090, altitude: 433),
      buildPoint(seq: 1, latitude: 1.15395, longitude: -76.65085, altitude: 435.5),
    ];

    await store.save(7, points);
    final loaded = await store.load(7);

    expect(loaded, hasLength(2));
    expect(loaded[1].latitude, points[1].latitude);
    expect(loaded[1].altitude, 435.5);
    expect(loaded[1].measurementId, 7);
    expect(loaded[0].timestamp, points[0].timestamp);
    expect(await store.load(8), isEmpty);
  });

  test('borra por medición y en bloque', () async {
    final store = InteriorPointsStore();
    await store.save(1, [buildPoint()]);
    await store.save(2, [buildPoint()]);

    await store.delete(1);
    expect(await store.load(1), isEmpty);
    expect(await store.load(2), hasLength(1));

    await store.deleteAll();
    expect(await store.load(2), isEmpty);
  });

  test('devuelve una lista vacía si los datos están dañados', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      InteriorPointsStore.keyFor(3): '{no es json',
    });

    expect(await InteriorPointsStore().load(3), isEmpty);
  });
}
