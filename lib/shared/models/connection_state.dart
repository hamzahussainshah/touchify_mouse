enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
  error,
}

class AppConnectionState {
  final ConnectionStatus status;
  final String? deviceId;
  final String? deviceIp;
  final bool isReconnecting;
  final String? errorMessage;

  const AppConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.deviceId,
    this.deviceIp,
    this.isReconnecting = false,
    this.errorMessage,
  });

  AppConnectionState copyWith({
    ConnectionStatus? status,
    String? deviceId,
    String? deviceIp,
    bool? isReconnecting,
    String? errorMessage,
  }) {
    return AppConnectionState(
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      deviceIp: deviceIp ?? this.deviceIp,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
