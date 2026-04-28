import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/connection_state.dart';
import '../../shared/models/device_model.dart';

final connectionProvider = StateNotifierProvider<ConnectionNotifier, AppConnectionState>((ref) {
  return ConnectionNotifier();
});

class ConnectionNotifier extends StateNotifier<AppConnectionState> {
  ConnectionNotifier() : super(const AppConnectionState());

  DeviceModel? _connectedDevice;
  DeviceModel? get connectedDevice => _connectedDevice;

  Future<void> connect(DeviceModel device) async {
    // Set _connectedDevice IMMEDIATELY so TrackpadScreen.addPostFrameCallback
    // (which fires ~10 ms after navigation) always reads a non-null device.
    // The previous code set it only after a 300 ms delay, causing the screen
    // to read null and bounce back to /connect on the first attempt.
    _connectedDevice = device;
    state = state.copyWith(
      status: ConnectionStatus.connected,
      deviceId: device.id,
      deviceIp: device.ipAddress,
    );
  }

  Future<void> reconnect() async {
    final lastDevice = _connectedDevice;
    if (lastDevice == null) return;

    state = state.copyWith(status: ConnectionStatus.reconnecting);

    for (int attempt = 0; attempt < 5; attempt++) {
      try {
        final socket = await Socket.connect(lastDevice.ipAddress, lastDevice.port).timeout(const Duration(seconds: 2));
        socket.destroy();
        state = state.copyWith(status: ConnectionStatus.connected);
        return;
      } catch (_) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    state = state.copyWith(status: ConnectionStatus.failed);
  }

  void setReconnecting(bool isReconnecting) {
    if (state.isReconnecting != isReconnecting) {
      state = state.copyWith(isReconnecting: isReconnecting);
    }
  }

  void disconnect() {
    _connectedDevice = null;
    state = const AppConnectionState(status: ConnectionStatus.disconnected);
  }
}
