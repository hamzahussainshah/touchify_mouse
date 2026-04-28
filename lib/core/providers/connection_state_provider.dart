import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/trackpad/services/trackpad_socket_service.dart';

/// Reactively emits true/false as the TCP socket connects/disconnects.
///
/// Uses an async* generator instead of exposing the broadcast stream directly.
/// Broadcast streams do NOT replay their last value to new subscribers, so any
/// widget built after the socket was already connected would always read null →
/// false from [StreamProvider.valueOrNull].  The generator fixes this by
/// immediately yielding the current [isConnected] state before forwarding all
/// future events from the broadcast stream.
final isSocketConnectedProvider = StreamProvider<bool>((ref) {
  final svc = TrackpadSocketService.instance;
  return (() async* {
    yield svc.isConnected;       // current state — replays for late subscribers
    yield* svc.connectionStatus; // all future connect/disconnect events
  })();
});
