import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/trackpad/services/trackpad_socket_service.dart';

/// Reactively emits true/false as the TCP socket connects/disconnects.
/// Use this in any panel that needs to gate its functionality on connection.
final isSocketConnectedProvider = StreamProvider<bool>((ref) {
  return TrackpadSocketService.instance.connectionStatus;
});
