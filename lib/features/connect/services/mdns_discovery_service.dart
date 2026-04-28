import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multicast_dns/multicast_dns.dart';
import '../../../shared/models/device_model.dart';

// NOT autoDispose — prevents the provider being silently garbage-collected
// while the Connect screen is mounted.  ConnectScreen must call stop() if it
// ever needs to tear the scan down explicitly.
final mdnsDiscoveryProvider =
    StateNotifierProvider<MdnsDiscoveryNotifier, List<DeviceModel>>(
  (ref) => MdnsDiscoveryNotifier()..startScan(),
);

class MdnsDiscoveryNotifier extends StateNotifier<List<DeviceModel>> {
  MdnsDiscoveryNotifier() : super([]);

  MDnsClient? _client;
  bool _isScanning = false;
  Timer? _scanTimer;

  void stop() {
    _scanTimer?.cancel();
    _scanTimer = null;
    try {
      _client?.stop();
    } catch (_) {}
    _client = null;
    _isScanning = false;
  }

  Future<void> startScan() async {
    if (_isScanning) return;
    stop();
    state = [];
    _isScanning = true;

    final client = MDnsClient();
    _client = client;

    // Auto-stop after 15 s to free the multicast socket
    _scanTimer = Timer(const Duration(seconds: 15), stop);

    try {
      await client.start();
      debugPrint('[mDNS] Client started — querying _touchifymouse._tcp.local');

      final ptrStream = client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_touchifymouse._tcp.local'),
      );

      ptrStream.listen(
        (ptr) {
          // Guard against _client being nulled out by a concurrent stop()
          final c = _client;
          if (c == null) return;
          debugPrint('[mDNS] PTR: ${ptr.domainName}');

          c.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName),
          ).listen(
            (srv) {
              final c2 = _client;
              if (c2 == null) return;
              debugPrint('[mDNS] SRV: ${srv.target}:${srv.port}');

              c2.lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              ).listen(
                (ip) async {
                  final c3 = _client;
                  if (c3 == null) return;
                  debugPrint('[mDNS] IP: ${ip.address.address}');

                  String osStr = 'unknown';
                  String nameStr = srv.target
                      .replaceAll('.local.', '')
                      .replaceAll('.local', '');

                  try {
                    await for (final txt in c3.lookup<TxtResourceRecord>(
                      ResourceRecordQuery.text(ptr.domainName),
                    )) {
                      for (final line in txt.text.split('\n')) {
                        if (line.startsWith('os=')) {
                          osStr = line.substring(3);
                        } else if (line.startsWith('name=')) {
                          nameStr = line.substring(5);
                        }
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

                  if (mounted && !state.any((d) => d.id == device.id)) {
                    state = [...state, device];
                    debugPrint('[mDNS] Device added: ${device.name} @ ${device.ipAddress}');
                  }
                },
                onError: (e) => debugPrint('[mDNS] IP lookup error: $e'),
              );
            },
            onError: (e) => debugPrint('[mDNS] SRV lookup error: $e'),
          );
        },
        onError: (e) {
          debugPrint('[mDNS] PTR stream error: $e');
          _isScanning = false;
        },
        onDone: () => debugPrint('[mDNS] PTR stream done'),
      );
    } catch (e) {
      debugPrint('[mDNS] startScan error: $e');
      _isScanning = false;
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
