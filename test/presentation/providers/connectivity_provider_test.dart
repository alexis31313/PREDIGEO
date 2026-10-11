import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predigeo/data/datasources/remote/connectivity_datasource.dart';
import 'package:predigeo/presentation/providers/connectivity_provider.dart';

class _FakeConnectivity extends ConnectivityDataSource {
  _FakeConnectivity({required this.connected, this.stream});

  final bool connected;
  final Stream<bool>? stream;

  @override
  Future<bool> isConnected() async => connected;

  @override
  Stream<bool> connectionStream() => stream ?? Stream<bool>.value(connected);
}

void main() {
  test('con conexión reporta estado connected y isOnline true', () async {
    final container = ProviderContainer(
      overrides: [
        connectivityDataSourceProvider
            .overrideWithValue(_FakeConnectivity(connected: true)),
      ],
    );
    addTearDown(container.dispose);

    container.listen(isOnlineProvider, (_, __) {});
    await container.read(isConnectedProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(isOnlineProvider), isTrue);
    expect(
        container.read(connectionStatusProvider), ConnectionStatus.connected);
  });

  test('sin conexión reporta estado disconnected y isOnline false', () async {
    final container = ProviderContainer(
      overrides: [
        connectivityDataSourceProvider
            .overrideWithValue(_FakeConnectivity(connected: false)),
      ],
    );
    addTearDown(container.dispose);

    container.listen(isOnlineProvider, (_, __) {});
    await container.read(isConnectedProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(isOnlineProvider), isFalse);
    expect(
      container.read(connectionStatusProvider),
      ConnectionStatus.disconnected,
    );
  });

  test('alterna automáticamente cuando cambia la red', () async {
    final controller = StreamController<bool>();
    final container = ProviderContainer(
      overrides: [
        connectivityDataSourceProvider.overrideWithValue(
          _FakeConnectivity(connected: true, stream: controller.stream),
        ),
      ],
    );
    addTearDown(() async {
      await controller.close();
      container.dispose();
    });

    final subscription = container.listen(isOnlineProvider, (_, __) {});
    addTearDown(subscription.close);

    await container.read(isConnectedProvider.future);
    expect(container.read(isOnlineProvider), isTrue);

    controller.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(isOnlineProvider), isFalse);

    controller.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(isOnlineProvider), isTrue);
  });
}
