import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'python_agent_service.dart';

class ConnectedClient {
  final String host; // ip:port the phone connected from
  final DateTime connectedAt;
  const ConnectedClient(this.host, this.connectedAt);
}

/// Live list of phones currently connected to the Python agent.
/// Subscribes to [agentPeerEvents] which is fed from agent stdout.
final connectedClientsProvider =
    StateNotifierProvider<ConnectedClientsNotifier, List<ConnectedClient>>(
  (_) => ConnectedClientsNotifier(),
);

class ConnectedClientsNotifier extends StateNotifier<List<ConnectedClient>> {
  ConnectedClientsNotifier() : super(const []) {
    _sub = agentPeerEvents.listen((ev) {
      if (ev.connected) {
        _add(ev.host);
      } else {
        _remove(ev.host);
      }
    });
  }

  StreamSubscription<AgentPeerEvent>? _sub;

  void _add(String host) {
    if (state.any((c) => c.host == host)) return;
    state = [...state, ConnectedClient(host, DateTime.now())];
  }

  void _remove(String host) {
    state = state.where((c) => c.host != host).toList(growable: false);
  }

  void clear() => state = const [];

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
