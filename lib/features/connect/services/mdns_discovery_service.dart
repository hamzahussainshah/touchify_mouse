import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multicast_dns/multicast_dns.dart';
import '../../../shared/models/device_model.dart';

final mdnsDiscoveryProvider = StateNotifierProvider.autoDispose<MdnsDiscoveryNotifier, List<DeviceModel>>((ref) {
  return MdnsDiscoveryNotifier()..startScan();
});

class MdnsDiscoveryNotifier extends StateNotifier<List<DeviceModel>> {
  MdnsDiscoveryNotifier() : super([]);

  MDnsClient? _client;
  bool _isScanning = false;

  void stop() {
    _client?.stop();
    _client = null;
    _isScanning = false;
  }

  Future<void> startScan() async {
    if (_isScanning) return;
    stop();
    state = [];
    _isScanning = true;
    _client = MDnsClient();

    try {
      await _client!.start();

      final ptrStream = _client!.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_touchifymouse._tcp.local'),
      );

      ptrStream.listen((ptr) {
        final srvStream = _client!.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        );

        srvStream.listen((srv) {
          final ipStream = _client!.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          );

          ipStream.listen((ip) async {
            final txtStream = _client!.lookup<TxtResourceRecord>(
              ResourceRecordQuery.text(ptr.domainName),
            );

            String osStr = 'Unknown';
            String nameStr = srv.target.replaceAll('.local', '');

            try {
              await for (final txt in txtStream) {
                final txtContent = txt.text.split('\n');
                for (var t in txtContent) {
                  if (t.contains('os=')) osStr = t.split('=')[1];
                  if (t.contains('name=')) nameStr = t.split('=')[1];
                }
                break;
              }
            } catch (_) {}

            final device = DeviceModel(
              id: '${ip.address.address}:${srv.port}',
              name: nameStr,
              ipAddress: ip.address.address,
              os: osStr,
              port: srv.port,
              signalStrength: 4,
            );

            if (!state.any((d) => d.id == device.id)) {
              state = [...state, device];
            }
          });
        });
      });
    } catch (_) {
      _isScanning = false;
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
