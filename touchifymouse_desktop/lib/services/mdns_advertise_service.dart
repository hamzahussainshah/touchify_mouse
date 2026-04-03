import 'package:bonsoir/bonsoir.dart';
import 'dart:io';

class MdnsAdvertiseService {
  BonsoirBroadcast? _broadcast;
  static final instance = MdnsAdvertiseService._();
  MdnsAdvertiseService._();

  Future<void> start() async {
    final service = BonsoirService(
      name: Platform.localHostname,
      type: '_touchifymouse._tcp',
      port: 35901,
      attributes: {
        'os': Platform.isMacOS ? 'mac' : 'windows',
        'version': '1.0.0',
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  Future<void> stop() async {
    await _broadcast?.stop();
  }
}
